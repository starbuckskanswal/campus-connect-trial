import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js';
import {
  getAuth,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js';
import {
  addDoc,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  onSnapshot,
  query,
  serverTimestamp,
  Timestamp,
  updateDoc,
  where,
} from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js';
import {
  getDownloadURL,
  getStorage,
  ref,
  uploadBytes,
} from 'https://www.gstatic.com/firebasejs/10.12.5/firebase-storage.js';

const firebaseConfig = window.CAMPUS_CONNECT_FIREBASE_CONFIG;
if (!firebaseConfig) {
  throw new Error('Missing Firebase config. Define window.CAMPUS_CONNECT_FIREBASE_CONFIG in index.html');
}

const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

const state = {
  currentUser: null,
  allowlistRecord: null,
  societies: [],
  editingEventId: null,
  editingPosterUrl: '',
  eventsUnsubscribe: null,
};

const MAX_POSTER_BYTES = 5 * 1024 * 1024;
const TARGET_POSTER_BYTES = 900 * 1024;
const MAX_POSTER_DIMENSION = 1600;

const loginButton = document.getElementById('loginButton');
const logoutButton = document.getElementById('logoutButton');
const statusBanner = document.getElementById('statusBanner');
const portalContent = document.getElementById('portalContent');
const formTitle = document.getElementById('formTitle');
const clearFormButton = document.getElementById('clearFormButton');
const eventForm = document.getElementById('eventForm');
const submitButton = document.getElementById('submitButton');
const societySelect = document.getElementById('society');
const eventsList = document.getElementById('eventsList');
const posterInput = document.getElementById('poster');
const posterPreviewWrap = document.getElementById('posterPreviewWrap');
const posterPreview = document.getElementById('posterPreview');

const titleInput = document.getElementById('title');
const subtitleInput = document.getElementById('subtitle');
const eventDateInput = document.getElementById('eventDate');
const eventTimeInput = document.getElementById('eventTime');
const locationInput = document.getElementById('location');
const reglinkInput = document.getElementById('reglink');
const registrationDeadlineInput = document.getElementById('registrationDeadline');
const descriptionInput = document.getElementById('description');
const duWideCheckbox = document.getElementById('duWideEvent');
const collegeBadge = document.getElementById('collegeBadge');

const provider = new GoogleAuthProvider();
provider.setCustomParameters({ prompt: 'select_account' });

loginButton.addEventListener('click', async () => {
  try {
    await signInWithPopup(auth, provider);
  } catch (error) {
    setStatus(`Google sign-in failed: ${error.message}`, 'error');
  }
});

logoutButton.addEventListener('click', async () => {
  try {
    await signOut(auth);
  } catch (error) {
    setStatus(`Sign-out failed: ${error.message}`, 'error');
  }
});

clearFormButton.addEventListener('click', () => {
  resetForm();
});

posterInput.addEventListener('change', () => {
  const file = posterInput.files?.[0];
  if (!file) {
    if (state.editingPosterUrl) {
      setPosterPreview(state.editingPosterUrl);
    } else {
      clearPosterPreview();
    }
    return;
  }

  const previewUrl = URL.createObjectURL(file);
  setPosterPreview(previewUrl);
});

eventForm.addEventListener('submit', async (event) => {
  event.preventDefault();

  if (!state.currentUser || !state.allowlistRecord) {
    setStatus('You are not authorized to publish events.', 'error');
    return;
  }
  if (!state.allowlistRecord.college) {
    setStatus(
      'Your society_admins record is missing a college. Ask an admin to add one before publishing.',
      'error',
    );
    return;
  }

  const title = titleInput.value.trim();
  const subtitle = subtitleInput.value.trim();
  const society = societySelect.value.trim();
  const eventDate = eventDateInput.value;
  const eventTime = eventTimeInput.value;
  const location = locationInput.value.trim();
  const reglink = normalizeOptionalUrl(reglinkInput.value.trim());
  const registrationDeadline = registrationDeadlineInput.value;
  const description = descriptionInput.value.trim();

  const missingFields = [];
  if (!title) missingFields.push('Event Name');
  if (!subtitle) missingFields.push('One-line Summary');
  if (!society) missingFields.push('Society');
  if (!eventDate) missingFields.push('Event Date');
  if (!eventTime) missingFields.push('Event Time');
  if (!location) missingFields.push('Location');
  if (!registrationDeadline) missingFields.push('Registration Deadline');
  if (!description) missingFields.push('Description');

  if (missingFields.length > 0) {
    setStatus(`Please fill in: ${missingFields.join(', ')}`, 'error');
    return;
  }

  const eventDateTime = new Date(`${eventDate}T${eventTime}`);
  const deadlineDateTime = new Date(registrationDeadline);

  if (Number.isNaN(eventDateTime.getTime()) || Number.isNaN(deadlineDateTime.getTime())) {
    setStatus('Invalid event date/time values.', 'error');
    return;
  }

  if (deadlineDateTime > eventDateTime) {
    setStatus('Registration deadline must be before event start time.', 'error');
    return;
  }

  setSubmitting(true);

  try {
    let posterUrl = state.editingPosterUrl || '';
    let posterUploadWarning = '';
    const file = posterInput.files?.[0];
    const userEmail = normalizeEmail(state.currentUser.email || '');

    if (file) {
      try {
        const uploadFile = await optimizePosterFile(file);
        if (uploadFile.size > MAX_POSTER_BYTES) {
          throw new Error('Poster is too large. Keep it under 5 MB.');
        }

        const storagePath = `poster_images/${state.currentUser.uid}/${Date.now()}_${sanitizeFileName(uploadFile.name)}`;
        const fileRef = ref(storage, storagePath);
        await uploadBytes(fileRef, uploadFile, {
          contentType: uploadFile.type || 'image/jpeg',
        });
        posterUrl = await getDownloadURL(fileRef);
      } catch (error) {
        if ((error?.code || '') === 'storage/unauthorized') {
          posterUploadWarning = ' Event was published without the poster because Storage permissions are still being finalized.';
          posterUrl = '';
        } else {
          throw error;
        }
      }
    }

    const payload = {
      email: userEmail,
      createdBy: userEmail,
      title,
      subtitle,
      society,
      college: state.allowlistRecord.college || '',
      visibility: duWideCheckbox?.checked ? 'du_wide' : 'college',
      location,
      datetime: Timestamp.fromDate(eventDateTime),
      registrationDeadline: Timestamp.fromDate(deadlineDateTime),
      description,
      reglink,
      imageUrl: posterUrl,
      posterUrl,
      updatedAt: serverTimestamp(),
    };

    if (state.editingEventId) {
      await updateDoc(doc(db, 'events', state.editingEventId), payload);
      setStatus(`Event updated successfully.${posterUploadWarning}`, 'success');
    } else {
      await addDoc(collection(db, 'events'), {
        ...payload,
        createdAt: serverTimestamp(),
      });
      setStatus(`Event published successfully.${posterUploadWarning}`, 'success');
    }

    resetForm();
  } catch (error) {
    setStatus(`Could not publish event: ${error.message}`, 'error');
  } finally {
    setSubmitting(false);
  }
});

onAuthStateChanged(auth, async (user) => {
  if (state.eventsUnsubscribe) {
    state.eventsUnsubscribe();
    state.eventsUnsubscribe = null;
  }

  state.currentUser = user;
  state.allowlistRecord = null;

  if (!user) {
    showLoggedOutState();
    return;
  }

  setStatus('Checking access permissions...', 'info');

  const normalizedEmail = normalizeEmail(user.email || '');
  const allowlistRecord = await getAllowlistRecord(normalizedEmail);
  if (!allowlistRecord) {
    portalContent.hidden = true;
    loginButton.hidden = true;
    logoutButton.hidden = false;
    setStatus('Access denied. Your email is not allowlisted in society_admins.', 'error');
    return;
  }

  state.allowlistRecord = allowlistRecord;
  loginButton.hidden = true;
  logoutButton.hidden = false;
  portalContent.hidden = false;

  await loadSocieties();
  prefillSociety();
  renderCollegeBadge();
  bindRealtimeEvents();

  setStatus(`Signed in as ${normalizedEmail}. Realtime publishing is active.`, 'success');
});

function showLoggedOutState() {
  loginButton.hidden = false;
  logoutButton.hidden = true;
  portalContent.hidden = true;
  resetForm();
  eventsList.innerHTML = '<p class="empty">No events yet.</p>';
  setStatus('Sign in with your allowlisted Google account.', 'info');
}

async function getAllowlistRecord(normalized) {
  if (!normalized) {
    return null;
  }

  try {
    const direct = await getDoc(doc(db, 'society_admins', normalized));
    if (direct.exists()) {
      const data = direct.data();
      // status is absent on pre-existing (pre-self-registration) docs,
      // which should still be treated as approved/active.
      const isApproved = !('status' in data) || data.status === 'active';
      if (data.active !== false && isApproved) {
        return data;
      }
      if (data.active !== false && data.status === 'pending') {
        setStatus(
          'Your society registration is still awaiting approval. Check back once an admin has approved it.',
          'info',
        );
      }
    }

  } catch (error) {
    setStatus(`Allowlist check failed: ${error.message}`, 'error');
  }

  return null;
}

async function loadSocieties() {
  const options = new Set();

  if (state.allowlistRecord?.society) {
    options.add(state.allowlistRecord.society);
  }

  try {
    const societiesSnap = await getDocs(collection(db, 'nsysuclubs'));
    societiesSnap.docs.forEach((docSnap) => {
      const name = (docSnap.data().name || '').trim();
      if (name) {
        options.add(name);
      }
    });
  } catch (_) {
    // Keep portal usable with allowlist-only society fallback.
  }

  state.societies = Array.from(options).sort((a, b) => a.localeCompare(b));

  societySelect.innerHTML = '<option value="">Select society</option>';
  state.societies.forEach((name) => {
    const option = document.createElement('option');
    option.value = name;
    option.textContent = name;
    societySelect.appendChild(option);
  });
}

function prefillSociety() {
  const preferred = state.allowlistRecord?.society;
  if (preferred && state.societies.includes(preferred)) {
    societySelect.value = preferred;
    return;
  }

  if (state.societies.length > 0) {
    societySelect.value = state.societies[0];
  }
}

function renderCollegeBadge() {
  if (!collegeBadge) {
    return;
  }
  const college = state.allowlistRecord?.college;
  collegeBadge.textContent = college
    ? `Posting as: ${state.allowlistRecord.society} · ${college}`
    : `Posting as: ${state.allowlistRecord?.society || ''} (no college on file)`;
}

function bindRealtimeEvents() {
  const userEmail = normalizeEmail(state.currentUser?.email || '');
  if (!userEmail) {
    return;
  }

  const q = query(
    collection(db, 'events'),
    where('email', '==', userEmail),
  );

  state.eventsUnsubscribe = onSnapshot(
    q,
    (snapshot) => {
      const events = snapshot.docs
        .map((docSnap) => ({ id: docSnap.id, ...docSnap.data() }))
        .sort((a, b) => toMillis(a.datetime) - toMillis(b.datetime));

      renderEvents(events);
    },
    (error) => {
      setStatus(`Realtime sync failed: ${error.message}`, 'error');
    },
  );
}

function renderEvents(events) {
  if (!events.length) {
    eventsList.innerHTML = '<p class="empty">No events published yet.</p>';
    return;
  }

  eventsList.innerHTML = '';

  events.forEach((eventData) => {
    const item = document.createElement('article');
    item.className = 'event-item';

    const title = escapeHtml(eventData.title || 'Untitled Event');
    const subtitle = escapeHtml(eventData.subtitle || '');
    const society = escapeHtml(eventData.society || 'General');
    const college = escapeHtml(eventData.college || '');
    const visibilityTag = eventData.visibility === 'du_wide' ? ' · DU-wide' : '';
    const location = escapeHtml(eventData.location || 'TBA');
    const posterUrl = eventData.imageUrl || eventData.posterUrl || '';
    const reglink = eventData.reglink || '';
    const posterMarkup = isHttpUrl(posterUrl)
      ? `<img class="event-poster" src="${escapeHtml(posterUrl)}" alt="${title} poster" />`
      : '';
    const reglinkMarkup = isHttpUrl(reglink)
      ? `<p class="meta"><a class="event-link" href="${escapeHtml(reglink)}" target="_blank" rel="noopener noreferrer">Open registration form</a></p>`
      : '';

    item.innerHTML = `
      ${posterMarkup}
      <h3>${title}</h3>
      <p class="meta">${subtitle}</p>
      <p class="meta">${formatDateTime(eventData.datetime)} • ${location}</p>
      <p class="meta">Society: ${society}${college ? ` · ${college}` : ''}${visibilityTag}</p>
      ${reglinkMarkup}
      <div class="event-actions">
        <button class="btn btn-ghost" data-action="edit" data-id="${eventData.id}">Edit</button>
        <button class="btn btn-danger" data-action="delete" data-id="${eventData.id}">Delete</button>
      </div>
    `;

    item.querySelector('[data-action="edit"]').addEventListener('click', () => {
      openEditMode(eventData);
    });

    item.querySelector('[data-action="delete"]').addEventListener('click', async () => {
      const confirmed = window.confirm(`Delete "${eventData.title || 'this event'}"?`);
      if (!confirmed) {
        return;
      }

      try {
        await deleteDoc(doc(db, 'events', eventData.id));
        setStatus('Event deleted successfully.', 'success');
      } catch (error) {
        setStatus(`Delete failed: ${error.message}`, 'error');
      }
    });

    eventsList.appendChild(item);
  });
}

function openEditMode(eventData) {
  state.editingEventId = eventData.id;
  state.editingPosterUrl = eventData.imageUrl || eventData.posterUrl || '';

  titleInput.value = eventData.title || '';
  subtitleInput.value = eventData.subtitle || '';
  societySelect.value = eventData.society || '';
  if (duWideCheckbox) {
    duWideCheckbox.checked = eventData.visibility === 'du_wide';
  }
  locationInput.value = eventData.location || '';
  reglinkInput.value = eventData.reglink || '';
  descriptionInput.value = eventData.description || '';

  const eventDate = toDate(eventData.datetime);
  const deadlineDate = toDate(eventData.registrationDeadline);

  if (eventDate) {
    eventDateInput.value = toDateInputValue(eventDate);
    eventTimeInput.value = toTimeInputValue(eventDate);
  }

  registrationDeadlineInput.value = deadlineDate ? toDateTimeLocalValue(deadlineDate) : '';

  if (state.editingPosterUrl) {
    setPosterPreview(state.editingPosterUrl);
  } else {
    clearPosterPreview();
  }

  formTitle.textContent = 'Edit Event';
  submitButton.textContent = 'Update Event';
  clearFormButton.hidden = false;
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function resetForm() {
  eventForm.reset();
  state.editingEventId = null;
  state.editingPosterUrl = '';
  formTitle.textContent = 'Publish Event';
  submitButton.textContent = 'Publish Event';
  clearFormButton.hidden = true;
  clearPosterPreview();
  prefillSociety();
}

function setPosterPreview(url) {
  posterPreview.src = url;
  posterPreviewWrap.hidden = false;
}

function clearPosterPreview() {
  posterPreview.src = '';
  posterPreviewWrap.hidden = true;
}

function normalizeOptionalUrl(value) {
  if (!value) {
    return '';
  }

  if (/^https?:\/\//i.test(value)) {
    return value;
  }

  if (/^[\w.-]+\.[a-z]{2,}([/?#].*)?$/i.test(value)) {
    return `https://${value}`;
  }

  return value;
}

function setSubmitting(isSubmitting) {
  submitButton.disabled = isSubmitting;
  submitButton.textContent = isSubmitting
    ? state.editingEventId
      ? 'Updating...'
      : 'Publishing...'
    : state.editingEventId
      ? 'Update Event'
      : 'Publish Event';
}

function setStatus(message, level = 'info') {
  statusBanner.textContent = message;
  statusBanner.dataset.level = level;

  if (level === 'error') {
    statusBanner.style.borderColor = '#fecdca';
    statusBanner.style.color = '#b42318';
    statusBanner.style.background = '#fff5f4';
    return;
  }

  if (level === 'success') {
    statusBanner.style.borderColor = '#a6f4c5';
    statusBanner.style.color = '#067647';
    statusBanner.style.background = '#ecfdf3';
    return;
  }

  statusBanner.style.borderColor = '#d9e1ef';
  statusBanner.style.color = '#475467';
  statusBanner.style.background = '#ffffff';
}

function toDate(value) {
  if (!value) {
    return null;
  }
  if (value instanceof Date) {
    return value;
  }
  if (typeof value.toDate === 'function') {
    return value.toDate();
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function toMillis(value) {
  const date = toDate(value);
  return date ? date.getTime() : 0;
}

function formatDateTime(value) {
  const date = toDate(value);
  if (!date) {
    return 'Date TBA';
  }

  return new Intl.DateTimeFormat('en-IN', {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}

function toDateInputValue(date) {
  const month = `${date.getMonth() + 1}`.padStart(2, '0');
  const day = `${date.getDate()}`.padStart(2, '0');
  return `${date.getFullYear()}-${month}-${day}`;
}

function toTimeInputValue(date) {
  const hours = `${date.getHours()}`.padStart(2, '0');
  const minutes = `${date.getMinutes()}`.padStart(2, '0');
  return `${hours}:${minutes}`;
}

function toDateTimeLocalValue(date) {
  return `${toDateInputValue(date)}T${toTimeInputValue(date)}`;
}

async function optimizePosterFile(file) {
  if (!(file instanceof File) || !file.type.startsWith('image/')) {
    return file;
  }

  if (file.size <= TARGET_POSTER_BYTES) {
    return file;
  }

  const image = await loadImageFromFile(file);
  const sourceWidth = image.naturalWidth || image.width;
  const sourceHeight = image.naturalHeight || image.height;
  const longestSide = Math.max(sourceWidth, sourceHeight);
  const scale = longestSide > MAX_POSTER_DIMENSION ? MAX_POSTER_DIMENSION / longestSide : 1;

  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(sourceWidth * scale));
  canvas.height = Math.max(1, Math.round(sourceHeight * scale));

  const context = canvas.getContext('2d');
  if (!context) {
    return file;
  }

  context.drawImage(image, 0, 0, canvas.width, canvas.height);

  let quality = 0.84;
  let blob = await canvasToBlob(canvas, 'image/jpeg', quality);

  while (blob.size > TARGET_POSTER_BYTES && quality > 0.56) {
    quality -= 0.08;
    blob = await canvasToBlob(canvas, 'image/jpeg', quality);
  }

  if (blob.size >= file.size) {
    return file;
  }

  return new File(
    [blob],
    replaceFileExtension(file.name, 'jpg'),
    { type: 'image/jpeg' },
  );
}

function loadImageFromFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onerror = () => {
      reject(new Error('Could not read the poster image.'));
    };

    reader.onload = () => {
      const image = new Image();
      image.onload = () => resolve(image);
      image.onerror = () => reject(new Error('Could not process the poster image.'));
      image.src = reader.result;
    };

    reader.readAsDataURL(file);
  });
}

function canvasToBlob(canvas, type, quality) {
  return new Promise((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) {
        resolve(blob);
        return;
      }

      reject(new Error('Could not compress the poster image.'));
    }, type, quality);
  });
}

function replaceFileExtension(fileName, nextExtension) {
  const baseName = fileName.replace(/\.[^.]+$/, '');
  return `${baseName}.${nextExtension}`;
}

function sanitizeFileName(fileName) {
  return fileName.replace(/[^a-zA-Z0-9_.-]/g, '_');
}

function normalizeEmail(email) {
  return (email || '').trim().toLowerCase();
}

function isHttpUrl(value) {
  if (!value) {
    return false;
  }

  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch (_) {
    return false;
  }
}

function escapeHtml(unsafe) {
  return unsafe
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
