// m8_parts.scad - A collection of things useful when developing with M8 fasteners

m8_screw_rad=8/2; // M8 screw hole radius
m8_oct_rad=4.35;    // Radius of an octagonal hole to take M8 rod
m8_nut_max_width=14.8;     // M8 Nut from point to point.
m8_nut_height=6.85;
m8_nut_min_width=12.9;  // Nut from flat to flat
m8_bolt_head_hole_rad=18/2;     // Diameter of hole for bolt head with room for socket wrench

608_bearing_rad=22/2;   // Radius of 608 bearing
608_bearing_height=7;   // height ditto

// Nut  slot for M8 nut
module m8_nut_slot() {
    translate([-m8_nut_max_width/2,-m8_nut_min_width/2,0]) cube([m8_nut_max_width+100,m8_nut_min_width,m8_nut_height]);
}

// Cavity for an m8 bolt and hex bolt head of specified length. Has room for socket wrench.
// Points down. Uses octagons so that it can be printed horizontally
module  m8_bolt_cavity(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m8_screw_rad*1.2,$fn=8);
    // Rotate to make holes flats parallel to axes. Tiny shift to fix booleans
    rotate([0,0,360/16]) translate([0,0,-0.001])
        cylinder(h=20,r=m8_bolt_head_hole_rad+0.2,$fn=8);
}

// Cavity for M8 nut that goes into the top of things. Slight overshoot to avoid booleans
module m8_nut_cavity(ht=m8_nut_height) {
    translate([0,0,0.01]) cylinder(h=ht+0.01,r=m8_nut_max_width/2,$fn=6);
}

// A nut cavity suitable for putting underneath things, with a nod to overhangs
module m8_nut_cavity_tapered() {
    // Cavity for m3 nut
    cylinder(h=m8_nut_height,r=m8_nut_max_width/2,$fn=6);
    translate([0,0,m8_nut_height])
        cylinder(h=1,r1=m8_nut_max_width/2,r2=m8_screw_rad*1.2,$fn=6);
}

// Octagonal hole for M8 bolt, no head, centred, length extends up and down
module  m8_screw_hole(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m8_screw_rad*1.2,$fn=8,center=true);
}

// Press fit cavity for 608 bearing. Cavity extends -Z, axle hole is 100 by default
module 608_bearing_press_cavity(axle_hole=100) union() {
    chamfer=0.6;
    difference() {
        // Bearing body
        translate([0,0,-608_bearing_height]) cylinder(h=608_bearing_height+1,r=608_bearing_rad,$fn=64);
        // Little divots for press fit
        divots=5;
        for(i=[1:divots]) rotate([0,0,i*360/divots])
            translate([608_bearing_rad,0,0]) cylinder(h=608_bearing_height*3,r1=0.3,r2=0.1,center=true);
    }
     // Chamfer around top edge of hole
    cylinder(h=chamfer*2,r1=608_bearing_rad,r2=608_bearing_rad+2*chamfer,center=true);
    // Axle hole
    translate([0,0,-axle_hole]) cylinder(h=axle_hole,r=608_bearing_rad-1,$fn=64);
}
