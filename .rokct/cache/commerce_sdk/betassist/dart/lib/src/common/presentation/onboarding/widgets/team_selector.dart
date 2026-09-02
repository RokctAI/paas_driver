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
import 'package:base_sdk/src/presentation/theme/app_style.dart'; // Import AppStyle and core styles

class TeamSelectorWidget extends StatefulWidget {
  final String title;
  final List<String> teams;
  final String? selectedTeam;
  final ValueChanged<String> onTeamSelected;

  const TeamSelectorWidget({
    super.key,
    required this.title,
    required this.teams,
    this.selectedTeam,
    required this.onTeamSelected,
  });

  @override
  State<TeamSelectorWidget> createState() => _TeamSelectorWidgetState();
}

class _TeamSelectorWidgetState extends State<TeamSelectorWidget> {
  String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedTeam;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppStyle.interBold(
            color: AppStyle.white,
            size: 24,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 250.h,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 2.2,
            ),
            itemCount: widget.teams.length,
            itemBuilder: (context, index) {
              final team = widget.teams[index];
              final isSelected = _selected == team;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selected = team;
                  });
                  widget.onTeamSelected(team);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppStyle.primary.withOpacity(0.15)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppStyle.primary : Colors.white10,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      team,
                      style: AppStyle.interSemi(
                        color: isSelected ? AppStyle.primary : AppStyle.white,
                        size: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
