// maus_baseboard_mounts.scad - Mounting parts for optional double-layer baseboard
// (c)2025 vik@diamondage.co.nz, released under the terms of the GPL V3 or later

version_string="MAUS V0.03";

include <../library/m3_parts.scad>
include <../library/metriccano.scad>


// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// 50mm pillars in L-shape with nut cavities
module baseboard_pillar() {
    translate([0,0,metriccano_unit]) rotate([180,0,0]) metriccano_square_strip(5);
    translate([0,0,metriccano_unit]) metriccano_square_strip(5);
    translate([0,metriccano_unit,0]) metriccano_square_strip(5);
}

// Foot with screw head recesses
module baseboard_foot() difference() {
    // Nice tapered plate
    hull() {
        metriccano_plate(2,2);
        translate([0,0,metriccano_unit/2]) scale([1.1,1.1,1]) metriccano_plate(2,2);
    }
    // Bunch of screw holes
    translate([0,0,metriccano_unit/2]) metriccano_screw_cavity(20);
    translate([metriccano_unit,0,metriccano_unit/2]) metriccano_screw_cavity(20);
    translate([0,metriccano_unit,metriccano_unit/2]) metriccano_screw_cavity(20);
    translate([metriccano_unit,metriccano_unit,metriccano_unit/2]) metriccano_screw_cavity(20);
}

baseboard_pillar();
translate([60,0,0]) baseboard_foot();