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

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:hardware_sdk/hardware_sdk.dart';
import 'models.dart';
import 'card_widgets.dart';

class ARScanScreen extends StatefulWidget {
  final SoccerMatch match;
  final bool isFav;
  final bool isFollowing;
  final double recommendedStake;
  final VoidCallback onPlaceBet;
  final bool showBetting;
  final SDKColors colors;

  const ARScanScreen({
    super.key,
    required this.match,
    required this.isFav,
    required this.isFollowing,
    required this.recommendedStake,
    required this.onPlaceBet,
    this.showBetting = true,
    this.colors = const SDKColors(),
  });

  @override
  State<ARScanScreen> createState() => _ARScanScreenState();
}

class _ARScanScreenState extends State<ARScanScreen> {
  StreamSubscription? _sensorSubscription;
  bool _isAnchored = false;

  @override
  void initState() {
    super.initState();
    try {
      _sensorSubscription = DeviceSensorManager.instance.tiltStream.listen(
        (TiltEvent event) {
          setState(() {
            _isAnchored = true;

            // AUTO SNAP-DOWN RULE (Tilted towards floor/user chest)
            if (event.direction == DeviceTiltDirection.down) {
              _sensorSubscription?.cancel();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Snapped back to 2D Dashboard (Camera inactive)."),
                  backgroundColor: widget.colors.surface,
                ),
              );
            }
          });
        },
        onError: (error) {
          setState(() {
            _isAnchored = true;
          });
        },
        cancelOnError: true,
      );
    } catch (e) {
      setState(() {
        _isAnchored = true;
      });
    }
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.colors.background,
      body: Stack(
        children: [
          // 1. Simulated TV Camera View Finder Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.9),
            child: Center(
              child: Opacity(
                opacity: 0.2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.video_camera_back, size: 100, color: Colors.white),
                    SizedBox(height: 16),
                    Text("[ TV SCANNER ACTIVE ]", style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2)),
                  ],
                ),
              ),
            ),
          ),
          
          // Camera Crosshair Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: widget.colors.accent.withOpacity(0.3), width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Gyroscope Live Spatial Overlay
          Positioned(
            left: 24,
            top: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi_tethering, color: widget.colors.accent, size: 16),
                    const SizedBox(width: 8),
                    Text("GYRO SENSORS: PITCH: ${_pitch.toStringAsFixed(2)} | ROLL: ${_roll.toStringAsFixed(2)}", 
                         style: TextStyle(fontSize: 10, color: widget.colors.textSecondary, fontFamily: 'monospace')),
                  ],
                ),
                const SizedBox(height: 4),
                Text("TILT PHONE DOWN TO SNAP-TO-DASHBOARD", style: TextStyle(fontSize: 9, color: widget.colors.accent)),
              ],
            ),
          ),

          // Exit Scanner button
          Positioned(
            right: 20,
            top: 50,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 3. AR Floating Anchored UI Card (Transforms based on Gyro measurements)
          if (_isAnchored)
            Center(
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_roll * 0.5)
                  ..rotateY(_pitch * 0.5),
                alignment: FractionalOffset.center,
                child: SizedBox(
                  width: 320,
                  height: 400,
                  child: FlipCard(
                    direction: FlipDirection.HORIZONTAL,
                    front: ARCardFront(match: widget.match, isFav: widget.isFav, colors: widget.colors),
                    back: ARCardBack(
                      match: widget.match, 
                      isFav: widget.isFav, 
                      isFollowing: widget.isFollowing, 
                      recommendedStake: widget.recommendedStake, 
                      onPlaceBet: widget.onPlaceBet,
                      showBetting: widget.showBetting,
                      colors: widget.colors,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
