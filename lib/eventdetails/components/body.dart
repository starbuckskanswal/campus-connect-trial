import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/favoriteservice.dart';
import 'package:url_launcher/url_launcher.dart';

class Body extends StatefulWidget {
  const Body({super.key, required this.eventsBundle});

  final EventsBundle eventsBundle;

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  bool _isInterested = false;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadPreferenceState();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.eventsBundle;
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerImage(context, event),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              event.title?.isNotEmpty == true ? event.title! : 'Untitled Event',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if ((event.subtitle ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                event.subtitle!,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 12),
          _infoTile(
            icon: Icons.calendar_month,
            title: 'Date & Time',
            value: event.startTime == null
                ? 'TBA'
                : DateFormat('EEE, d MMM yyyy • hh:mm a')
                    .format(event.startTime!),
          ),
          _infoTile(
            icon: Icons.location_on_outlined,
            title: 'Location',
            value: (event.location ?? '').isEmpty ? 'TBA' : event.location!,
          ),
          _infoTile(
            icon: Icons.groups_outlined,
            title: 'Society',
            value: (event.society ?? '').isEmpty ? 'General' : event.society!,
          ),
          _infoTile(
            icon: Icons.timer_outlined,
            title: 'Registration Deadline',
            value: event.registrationDeadline == null
                ? 'Not specified'
                : DateFormat('d MMM yyyy • hh:mm a')
                    .format(event.registrationDeadline!),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Event Description',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Text(
              (event.description ?? '').isEmpty
                  ? 'No description provided.'
                  : event.description!,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleDismissed,
                    icon: Icon(
                        _isDismissed ? Icons.visibility_off : Icons.visibility),
                    label: Text(_isDismissed ? 'Hidden' : 'Not Interested'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _toggleInterested,
                    icon: Icon(
                        _isInterested ? Icons.favorite : Icons.favorite_border),
                    label: Text(_isInterested ? 'Interested' : 'Save'),
                  ),
                ),
              ],
            ),
          ),
          if ((event.reglink ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _launchRegistrationLink(event.reglink!),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open Registration Form'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerImage(BuildContext context, EventsBundle event) {
    final posterUrl = event.imageSrc ?? '';

    // Full Instagram portrait poster (4:5), never cropped.
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: posterUrl.isNotEmpty
              ? GestureDetector(
                  onTap: () => _openFullScreenPoster(context, posterUrl),
                  child: Container(
                    color: Colors.black,
                    child: CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      progressIndicatorBuilder: (context, url, progress) =>
                          const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (context, url, error) {
                        return _fallbackPoster(context);
                      },
                    ),
                  ),
                )
              : _fallbackPoster(context),
        ),
        Positioned(
          top: 34,
          left: 12,
          child: CircleAvatar(
            backgroundColor: Colors.black.withValues(alpha: 0.45),
            child: const BackButton(color: Colors.white),
          ),
        ),
        if (posterUrl.isNotEmpty)
          Positioned(
            bottom: 10,
            right: 12,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.45),
              child: IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: () => _openFullScreenPoster(context, posterUrl),
              ),
            ),
          ),
      ],
    );
  }

  void _openFullScreenPoster(BuildContext context, String posterUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.contain,
                progressIndicatorBuilder: (context, url, progress) =>
                    const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) =>
                    _fallbackPoster(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackPoster(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 62,
        color: colors.onSecondaryContainer,
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Future<void> _loadPreferenceState() async {
    final id = widget.eventsBundle.id;
    if (id == null || id.isEmpty) {
      return;
    }

    final interested = await FavoritesService.isInterested(id);
    final dismissed = await FavoritesService.isDismissed(id);

    if (!mounted) {
      return;
    }

    setState(() {
      _isInterested = interested;
      _isDismissed = dismissed;
    });
  }

  Future<void> _toggleInterested() async {
    final id = widget.eventsBundle.id;
    if (id == null || id.isEmpty) {
      return;
    }

    await FavoritesService.setInterested(id, !_isInterested);
    await _loadPreferenceState();
  }

  Future<void> _toggleDismissed() async {
    final id = widget.eventsBundle.id;
    if (id == null || id.isEmpty) {
      return;
    }

    await FavoritesService.setDismissed(id, !_isDismissed);
    await _loadPreferenceState();
  }

  Future<void> _launchRegistrationLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
