import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stephenscalender2024/eventshome/models/events_bundle.dart';
import 'package:stephenscalender2024/size_config.dart';

import '../../favoriteservice.dart';
import '../../societyiconresolver.dart';

class EventsBundleCard extends StatefulWidget {
  final EventsBundle eventsBundle;

  const EventsBundleCard({Key? key, required this.eventsBundle})
      : super(key: key);

  @override
  State<EventsBundleCard> createState() => _EventsBundleCardState();
}

class _EventsBundleCardState extends State<EventsBundleCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    // Use a unique key for the event – assuming widget.eventsBundle.id exists
    final id = widget.eventsBundle.id ?? '';
    if (id.isEmpty) return;

    final fav = await FavoritesService.isFavorite(id);
    if (mounted) {
      setState(() {
        _isFavorite = fav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final id = widget.eventsBundle.id ?? '';
    if (id.isEmpty) return;

    setState(() {
      _isFavorite = !_isFavorite;
    });

    await FavoritesService.toggleFavorite(id);
  }


  @override
  Widget build(BuildContext context) {
    double? defaultSize = SizeConfig.defaultSize;

    return AspectRatio(
      aspectRatio: 1.65,
      child: Stack(
        children: [
          // MAIN CARD BACKGROUND + CONTENT
          Container(
            decoration: BoxDecoration(
              color: widget.eventsBundle.color,
              borderRadius: BorderRadius.circular(defaultSize! * 1.8),
            ),
            child: Row(
              children: [
                // LEFT SIDE CONTENT
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(defaultSize * 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        Text(
                          widget.eventsBundle.title ?? "",
                          style: TextStyle(
                            fontSize: defaultSize * 2.2,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: defaultSize * 0.5),
                        Text(
                          widget.eventsBundle.description ?? "",
                          style: const TextStyle(color: Colors.white54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        buildInfoRow(
                          defaultSize,
                          iconSrc: Icons.date_range,
                          text: DateFormat('yyyy-MM-dd')
                              .format(widget.eventsBundle.startTime!),
                        ),
                        SizedBox(height: defaultSize * 0.5),
                        SizedBox(
                          height: defaultSize * 2.2, // enough vertical room
                          child: buildInfoRow(
                            defaultSize,
                            iconSrc: Icons.group,
                            text: widget.eventsBundle.society ?? "",
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),

                // RIGHT SIDE ICON
                Padding(
                  padding: EdgeInsets.only(right: defaultSize),
                  child: FutureBuilder<String>(
                    future: SocietyIconResolver.getIconForSociety(
                        widget.eventsBundle.society ?? ""),
                    builder: (context, snapshot) {
                      final iconUrl = snapshot.data ?? "";

                      return SizedBox(
                        width: defaultSize * 9,
                        height: defaultSize * 9,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: iconUrl.isEmpty
                              ? Image.asset(
                            "assets/images/quizclub.png",
                            fit: BoxFit.contain,
                            color: Colors.white,
                          )
                              : CachedNetworkImage(
                            imageUrl: iconUrl,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) {
                              return Image.asset(
                                "assets/images/quizclub.png",
                                fit: BoxFit.contain,
                                color: Colors.white,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ❤️ FAVORITE ICON - NOW POSITIONED CORRECTLY
          Positioned(
            bottom: defaultSize * 0.6,
            right: defaultSize * 0.6,
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.redAccent : Colors.white,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
    );
  }


  Row buildInfoRow(double defaultSize, {IconData? iconSrc, text}) {
    return Row(
      children: [
        Icon(
          iconSrc,
          color: Colors.white,
        ),
        SizedBox(width: defaultSize),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
