// optic_probe_holder.scad -Holds a standard 125/9 fibre optic connector on a PIKA Probe Arm
// (c)2026 vik@olliver.fsmily.gen.nz GPLV3 or later applies

include <../library/m3_parts.scad>

// A square fibre optic connector socket, height = very big.
plug_square=4.65;    // It's a square cross-section plug this buig
tab_width=3.8;  // Dimensions of tab on side of optical plug.
tab_ht=1.6;
// Make sure the socket will be big enough to hold the tab
fibre_socket_square=plug_square+2*tab_ht+1;
fibre_socket_deep=4;   // Depth of the socket. Note this controlls the height of the probe tip.

// Holds the optical fibre plug.
// Needs to lean a bit because the probe arm pivots down.
module fibre_socket() {
    verybig=999;
    rotate([-2,0,0]) translate([0,0,verybig/2]) {
        // Hole for fibre
        cube([plug_square,plug_square,verybig],center=true);
        // Slot for the tab on it.
        translate([0,0.01-(plug_square+tab_ht)/2,0]) cube([tab_width,tab_ht,verybig],center=true);
    }
}

// Perforated tab used to hold the fleures etc. to the Z Axis Driver's Probe Arm
tab_rad=10/2;
tab_thick=6;
handle_depth=8;    // Handle sticks out this much.

 module attachment_tab(thickness=tab_thick) {
    difference() {
        hull() {
            // Nice, smooth transition to the handle
            translate([tab_rad,handle_depth+tab_rad,0]) cylinder(h=thickness,r=tab_rad,$fn=64);
            cube([fibre_socket_square,tab_thick,thickness]);
        }
        // Perforate for a screw
        translate([tab_rad,handle_depth+tab_rad,0]) rotate([0,0,180/8])
            m3_screw_hole(thickness*3);
    }
}

support_ht=9;
attachment_tab();
translate([0,-fibre_socket_square,0]) difference() {
    union() {
        // Supportive bit for fibre connector
        translate([0,-tab_ht,0]) cube([fibre_socket_square,fibre_socket_square+tab_ht,fibre_socket_deep]);
        // This bit does not crowd the tab
        translate([0,(fibre_socket_square-plug_square)/2,0])
            cube([fibre_socket_square,fibre_socket_square-tab_ht,support_ht]);
    }
    translate([fibre_socket_square/2,fibre_socket_square/2,-1]) fibre_socket();
}
