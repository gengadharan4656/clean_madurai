import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../services/location_service.dart';
import '../../models/dustbin_model.dart';
import '../../utils/app_theme.dart';

class DustbinMapScreen extends StatefulWidget {
  const DustbinMapScreen({super.key});

  @override
  State<DustbinMapScreen> createState() => _DustbinMapScreenState();
}

class _DustbinMapScreenState extends State<DustbinMapScreen> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<DustbinModel> _nearbyDustbins = [];
  DustbinModel? _selectedDustbin;
  bool _isLoading = true;
  String _errorMessage = '';
  double _radiusKm = 2.0;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // FIXED: proper permission handling
      final position = await LocationService.getCurrentPosition(
        context: context,
        showPermissionDialog: true,
      );

      if (position == null) {
        setState(() {
          _errorMessage = 'Could not get location. Showing Madurai center.';
          _isLoading = false;
        });
        // Load dustbins from Madurai center anyway
        await _loadNearbyDustbins(9.9252, 78.1198);
        return;
      }

      setState(() => _currentPosition = position);
      await _loadNearbyDustbins(position.latitude, position.longitude);

      // Move map to current location
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Location error: ${e.toString()}';
          _isLoading = false;
        });
        await _loadNearbyDustbins(9.9252, 78.1198);
      }
    }
  }

  Future<void> _loadNearbyDustbins(double lat, double lng) async {
    try {
      final dustbins = await LocationService.findNearbyDustbins(
        latitude: lat,
        longitude: lng,
        radiusKm: _radiusKm,
        limit: 30,
      );

      if (mounted) {
        setState(() {
          _nearbyDustbins = dustbins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load dustbins';
          _isLoading = false;
        });
      }
    }
  }

  List<DustbinModel> get _filteredDustbins {
    if (_filterType == 'all') return _nearbyDustbins;
    if (_filterType == 'full') return _nearbyDustbins.where((d) => d.isFull).toList();
    return _nearbyDustbins.where((d) => d.type == _filterType).toList();
  }

  Color _getDustbinColor(DustbinModel dustbin) {
    if (dustbin.fillLevel >= 90) return AppTheme.error;
    if (dustbin.fillLevel >= 70) return AppTheme.warning;
    if (dustbin.fillLevel >= 40) return AppTheme.accent;
    return AppTheme.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Dustbins Near Me'),
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primary),
            onPressed: _initLocation,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppTheme.textSecondary),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          else
            _buildMap(),

          // Error Banner
          if (_errorMessage.isNotEmpty)
            Positioned(
              top: 12, left: 16, right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.warning, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage,
                          style: const TextStyle(color: AppTheme.warning, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // Stats Bar
          Positioned(
            bottom: _selectedDustbin != null ? 210 : 16,
            left: 16, right: 16,
            child: _buildStatsBar(),
          ),

          // Selected Dustbin Card
          if (_selectedDustbin != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: _buildDustbinCard(_selectedDustbin!),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentPosition != null) {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              15.0,
            );
          } else {
            _initLocation();
          }
        },
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.my_location_rounded, color: AppTheme.bg),
      ),
    );
  }

  Widget _buildMap() {
    final defaultCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(9.9252, 78.1198);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: defaultCenter,
        zoom: 14.0,
        minZoom: 10.0,
        maxZoom: 18.0,
        onTap: (_, __) => setState(() => _selectedDustbin = null),
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.cleanmadurai.app',
          backgroundColor: AppTheme.bg,
        ),

        // Dustbin markers
        MarkerLayer(
          markers: [
            // Current location marker
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 40, height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentBlue.withOpacity(0.4),
                        blurRadius: 12, spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 20),
                ),
              ),

            // Dustbin markers
            ..._filteredDustbins.map((dustbin) {
              final color = _getDustbinColor(dustbin);
              final isSelected = _selectedDustbin?.id == dustbin.id;
              return Marker(
                point: LatLng(dustbin.latitude, dustbin.longitude),
                width: isSelected ? 48 : 36,
                height: isSelected ? 48 : 36,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedDustbin = dustbin),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color.withOpacity(isSelected ? 1.0 : 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : color.withOpacity(0.3),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 16, spreadRadius: 4)]
                          : null,
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      color: isSelected ? AppTheme.bg : Colors.white,
                      size: isSelected ? 24 : 18,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    final fullCount = _nearbyDustbins.where((d) => d.isFull).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_nearbyDustbins.length}', 'Nearby', AppTheme.primary),
          _buildStatItem('$fullCount', 'Full', AppTheme.error),
          _buildStatItem('${_radiusKm.round()}km', 'Radius', AppTheme.accentBlue),
          _buildStatItem(
              '${_nearbyDustbins.isNotEmpty ? _nearbyDustbins.first.distanceKm?.toStringAsFixed(2) ?? '-' : '-'}km',
              'Closest', AppTheme.accent),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
      ],
    );
  }

  Widget _buildDustbinCard(DustbinModel dustbin) {
    final fillColor = dustbin.fillLevel >= 80
        ? AppTheme.error
        : dustbin.fillLevel >= 60
            ? AppTheme.warning
            : AppTheme.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(
            color: AppTheme.textMuted, borderRadius: BorderRadius.circular(2),
          )),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.delete_rounded, color: fillColor, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dustbin.name,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(dustbin.address,
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dustbin.distanceKm != null
                        ? '${dustbin.distanceKm!.toStringAsFixed(2)} km'
                        : '-- km',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text('Ward ${dustbin.ward}',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fill Level', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Text('${dustbin.fillLevel}%',
                            style: TextStyle(color: fillColor, fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: dustbin.fillLevel / 100,
                        backgroundColor: AppTheme.cardBorder,
                        color: fillColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dustbin.statusText,
                  style: TextStyle(color: fillColor, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {/* Open Maps */},
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {/* Report full */},
                  icon: const Icon(Icons.report_problem_rounded, size: 18),
                  label: const Text('Report Full'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dustbin.isFull ? AppTheme.error : AppTheme.primary,
                    foregroundColor: AppTheme.bg,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filter Dustbins',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              const Text('Radius', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              Slider(
                value: _radiusKm,
                min: 0.5, max: 5.0, divisions: 9,
                activeColor: AppTheme.primary,
                inactiveColor: AppTheme.cardBorder,
                label: '${_radiusKm.toStringAsFixed(1)} km',
                onChanged: (v) => setModal(() => _radiusKm = v),
              ),
              const SizedBox(height: 8),
              const Text('Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'full', 'public', 'large', 'market', 'residential']
                    .map((type) => ChoiceChip(
                          label: Text(type.toUpperCase()),
                          selected: _filterType == type,
                          selectedColor: AppTheme.primary.withOpacity(0.2),
                          backgroundColor: AppTheme.card,
                          side: BorderSide(
                            color: _filterType == type ? AppTheme.primary : AppTheme.cardBorder,
                          ),
                          labelStyle: TextStyle(
                            color: _filterType == type ? AppTheme.primary : AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          onSelected: (selected) => setModal(() => _filterType = type),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {});
                    if (_currentPosition != null) {
                      _loadNearbyDustbins(_currentPosition!.latitude, _currentPosition!.longitude);
                    }
                  },
                  child: const Text('Apply Filter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
