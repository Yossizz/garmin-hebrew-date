using Toybox.Position;
using Toybox.Sensor;
using Toybox.Math;
using Toybox.System;

module Compass {
    
    // Jerusalem coordinates (Temple Mount / Old City)
    const JERUSALEM_LAT = 31.7781;
    const JERUSALEM_LON = 35.2360;
    
    // Get current GPS location with quality information
    // Returns: {lat, lon, accuracy, quality} or null if unavailable
    function getCurrentLocation() {
        try {
            var info = Position.getInfo();
            
            if (info == null) {
                return null;
            }
            
            // Always return info about GPS state, even if no position yet
            var result = {
                "lat" => null,
                "lon" => null,
                "accuracy" => info.accuracy,
                "quality" => getGpsQuality(info.accuracy)
            };
            
            if (info.position == null) {
                return result;
            }
            
            var position = info.position;
            var coords = position.toDegrees();
            
            if (coords == null || coords.size() < 2) {
                return result;
            }
            
            result["lat"] = coords[0];
            result["lon"] = coords[1];
            
            return result;
        } catch (ex) {
            return null;
        }
    }
    
    // Convert GPS accuracy to quality percentage (0-100)
    // Returns: 0 (no signal) to 100 (excellent signal)
    function getGpsQuality(accuracy) {
        if (accuracy == null) {
            return 0;
        }
        
        // Position.QUALITY constants:
        // NOT_AVAILABLE = 0, LAST_KNOWN = 1, POOR = 2, USABLE = 3, GOOD = 4
        if (accuracy == Position.QUALITY_NOT_AVAILABLE) {
            return 0;
        } else if (accuracy == Position.QUALITY_LAST_KNOWN) {
            return 25;
        } else if (accuracy == Position.QUALITY_POOR) {
            return 50;
        } else if (accuracy == Position.QUALITY_USABLE) {
            return 75;
        } else if (accuracy == Position.QUALITY_GOOD) {
            return 100;
        }
        
        return 0;
    }
    
    // Check if GPS is available
    function isGpsAvailable() {
        var info = Position.getInfo();
        return (info != null && info.position != null && info.accuracy != Position.QUALITY_NOT_AVAILABLE);
    }
    
    // Calculate bearing from point 1 to point 2
    // Returns bearing in degrees (0-360, where 0 = North)
    function calculateBearing(lat1, lon1, lat2, lon2) {
        try {
            if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
                return null;
            }
            
            // Convert to radians
            var lat1Rad = Math.toRadians(lat1);
            var lat2Rad = Math.toRadians(lat2);
            var lon1Rad = Math.toRadians(lon1);
            var lon2Rad = Math.toRadians(lon2);
            
            var dLon = lon2Rad - lon1Rad;
            
            // Calculate bearing using atan2
            var y = Math.sin(dLon) * Math.cos(lat2Rad);
            var x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - 
                    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
            
            var bearing = Math.atan2(y, x);
            
            // Convert to degrees and normalize to 0-360
            bearing = Math.toDegrees(bearing);
            bearing = (bearing.toNumber() + 360) % 360;
            
            return bearing.toDouble();
        } catch (ex) {
            return null;
        }
    }
    
    // Calculate bearing from current location to Jerusalem
    // Returns: bearing in degrees (0-360) or null if GPS unavailable
    function getBearingToJerusalem(currentLat, currentLon) {
        if (currentLat == null || currentLon == null) {
            return null;
        }
        
        return calculateBearing(currentLat, currentLon, JERUSALEM_LAT, JERUSALEM_LON);
    }
    
    // Get compass heading from watch's magnetometer
    // Returns: heading in degrees (0-360, where 0 = North) or null if unavailable
    function getCompassHeading() {
        try {
            var info = Sensor.getInfo();
            
            if (info == null) {
                return null;
            }
            
            // Try direct heading first
            if (info has :heading && info.heading != null) {
                // heading is in radians, convert to degrees
                var headingDegrees = Math.toDegrees(info.heading);
                headingDegrees = (headingDegrees.toNumber() + 360) % 360;
                return headingDegrees.toDouble();
            }
            
            // Try magnetometer data
            if (info has :magX && info has :magY) {
                var magX = info.magX;
                var magY = info.magY;
                
                if (magX != null && magY != null) {
                    // Calculate heading from magnetometer
                    var heading = Math.atan2(magY, magX);
                    heading = Math.toDegrees(heading);
                    heading = (heading.toNumber() + 360) % 360;
                    return heading.toDouble();
                }
            }
            
            return null;
        } catch (ex) {
            return null;
        }
    }
    
    // Calculate arrow angle for drawing
    // Returns: angle in degrees (0-360) where arrow should point
    // Formula: bearing_to_jerusalem - compass_heading
    function calculateArrowAngle(bearingToJerusalem, compassHeading) {
        if (bearingToJerusalem == null || compassHeading == null) {
            return null;
        }
        
        // Calculate relative angle
        var angle = bearingToJerusalem - compassHeading;
        
        // Normalize to 0-360
        angle = (angle.toNumber() + 360) % 360;
        
        return angle.toDouble();
    }
}
