// m6_parts.scad - A collection of things useful when developing with M6 fasteners

m6_screw_rad=3.2; // M6 screw hole radius
m6_screw_head_rad=5.9;    // Radius of the average M6 posi screw head
m6_screw_head_height=4.8;
m6_nut_max_width=12.8;     // M6 Nut from point to point.
m6_pillar_max_width=11.8;    // M6 pillar width, point to point
m6_nut_height=5;
m6_nut_min_width=11.6;  // Nut from flat to flat

// Pecular square nut dimensions, domed on one side.
m6_square_nut_width=10.3;
m6_square_nut_height=4.9;

// Cavity for M6 nut that goes into the top of things. Slight overshoot to avoid booleans
module m6_nut_cavity(ht=m6_nut_height) {
    translate([0,0,0.01]) cylinder(h=ht+0.01,r=m6_nut_max_width/2,$fn=6);
}

// A nut cavity for putting underneath things, with a nod to overhangs
module m6_nut_cavity_tapered() {
    // Cavity for m6 nut
    cylinder(h=m6_nut_height,r=m6_nut_max_width/2,$fn=6);
    translate([0,0,m6_nut_height])
        cylinder(h=1,r1=m6_nut_max_width/2,r2=m6_screw_rad*1.2,$fn=6);
}

// Nut  slot for M6 nut
module m6_nut_slot() {
    translate([-m6_nut_max_width/2,-m6_nut_min_width/2,0]) cube([m6_nut_max_width+100,m6_nut_min_width,m6_nut_height]);
}

// Cavity for an M6 screw and screw head of specified length.
// Points down. Uses octagons so that it can be printed horizontally
module  m6_screw_cavity(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m6_screw_rad*1.2,$fn=8);
    // Rotate to make hole sflats parallel to axes. Tiny shift to fix booleans
    rotate([0,0,360/16]) translate([0,0,-0.001])
        cylinder(h=10,r=m6_screw_head_rad*1.2,$fn=8);
}

// Octagonal hole for screw, no head, centred, length extends up and down
module  m6_screw_hole(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m6_screw_rad*1.2,$fn=8,center=true);
}

m6_thumbscrew_height=10;
m6_thumbscrew_rad=10;
// Thumbscrew with ridges. Screw head fits in top depression, nut on screw
// shaft holds it in place.
//  rad: Optional radius for thumbscrew knob (default 5, see above)
module m6_thumbscrew_knob(rad=m6_thumbscrew_rad) {
    m6_thumbscrew_ridges=floor(rad*3.2);
    difference() {
        union() {
            for (i=[0:m6_thumbscrew_ridges]) rotate([0,0,360/m6_thumbscrew_ridges*i])
                translate([rad,0,m6_thumbscrew_height/2])
                    cube([1,1,m6_thumbscrew_height],center=true);
            cylinder(h=m6_thumbscrew_height,r=rad);
        }
        translate([0,0,m6_thumbscrew_height-m6_screw_head_height]) m6_screw_cavity(m6_thumbscrew_height);
    }
}
