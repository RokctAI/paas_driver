// Copyright (c) 2026 ROKCT INTELLIGENCE (PTY) LTD
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:base_sdk/src/presentation/theme/app_style.dart';

import 'buttons/buttons_bouncing_effect.dart';

class MapsList extends StatefulWidget {
  final Coords location;
  final String title;

  const MapsList({super.key, required this.location, required this.title});

  @override
  State<MapsList> createState() => _MapsListState();
}

class _MapsListState extends State<MapsList> {
  List<AvailableMap> availableMaps = [];

  @override
  void initState() {
    installedMaps();
    super.initState();
  }

  installedMaps() async {
    availableMaps = await MapLauncher.installedMaps;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        shrinkWrap: true,
        itemCount: availableMaps.length,
        itemBuilder: (context, index) {
          return ButtonsBouncingEffect(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
              decoration: BoxDecoration(
                  color: AppStyle.white, borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                onTap: () => availableMaps[index].showMarker(
                  coords: widget.location,
                  title: widget.title,
                ),
                title: Text(availableMaps[index].mapName),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: SvgPicture.asset(
                    availableMaps[index].icon,
                    height: 30.0,
                    width: 30.0,
                  ),
                ),
              ),
            ),
          );
        });
  }
}
