// nut_tool.scad - Utensil for pushing nuts into nut slots on the PIKA 3D Printer
// (c)2026 vik@diamondage.co.nz, released under the terms of the GPL V3 or later

include <m3_parts.scad>

tolerance=0.2;      // Adjust for your printer
handle_length=30;
edge_rad=5;
thumb_rad=9;    // Radius of a notional human thumb
tool_width=m3_nut_min_width-tolerance*2;

// The pointy bit
translate([-7,0,0]) difference() {
    cube([30,tool_width,m3_nut_height-tolerance*2]);
    translate([0,tool_width/2,0])
        cylinder(h=m3_nut_height*3,r=m3_nut_max_width/2,center=true,$fn=6);
}

// Outline of handle
module handle_outline() {
    hull() {
        cube([0.1,tool_width,m3_nut_height]);
        translate([0,0,edge_rad/2]) hull() {
            translate([handle_length-edge_rad,0,0]) {
                sphere(edge_rad,$fn=32);
                translate([0,tool_width,0]) sphere(edge_rad,$fn=32);
            }
            translate([handle_length-thumb_rad*2,0,0]) {
                sphere(edge_rad,$fn=32);
                translate([0,tool_width,0]) sphere(edge_rad,$fn=32);
            }
        }
    }
}

// Chop a thumb depression out and make the base flat
difference() {
    handle_outline();
    // Squished thumb
    translate([handle_length-thumb_rad-edge_rad/2,tool_width/2,thumb_rad*1.5-edge_rad])
        scale([1,1,0.5]) sphere(thumb_rad,$fn=64);
    // Flat base
    translate([0,0,-100])
        cube(200,center=true);
}
