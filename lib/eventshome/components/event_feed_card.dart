import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';

class EventFeedCard extends StatelessWidget {
  const EventFeedCard({
    super.key,
    required this.event,
    required this.isInterested,
    required this.isDismissed,
    required this.onInterestedToggle,
    required this.onDismissToggle,
    required this.onTap,
  });

  final EventsBundle event;
  final bool isInterested;
  final bool isDismissed;
  final VoidCallback onInterestedToggle;
  final VoidCallback onDismissToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final start = event.startTime;
    final deadline = event.registrationDeadline;
    final poster = event.imageSrc ?? '';
    final hasPoster = poster.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: hasPoster
                    ? CachedNetworkImage(
                        imageUrl: poster,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) {
                          return _posterFallback(context);
                        },
                      )
                    : _posterFallback(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tag(
                        context,
                        event.society?.isNotEmpty == true
                            ? event.society!
                            : 'General',
                      ),
                      if (deadline != null)
                        _tag(context,
                            'Reg ends ${DateFormat.MMMd().format(deadline)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title?.isNotEmpty == true
                        ? event.title!
                        : 'Untitled Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  if ((event.subtitle ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle!,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          start != null
                              ? DateFormat('EEE, d MMM • hh:mm a').format(start)
                              : 'Time TBA',
                          style: TextStyle(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location?.isNotEmpty == true
                              ? event.location!
                              : 'Location TBA',
                          style: TextStyle(color: colors.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onDismissToggle,
                          icon: Icon(
                            isDismissed
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          label:
                              Text(isDismissed ? 'Hidden' : 'Not Interested'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onInterestedToggle,
                          icon: Icon(
                            isInterested
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                          ),
                          label: Text(isInterested ? 'Interested' : 'Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterFallback(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.secondaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: 46,
        color: colors.onSecondaryContainer,
      ),
    );
  }

  Widget _tag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
