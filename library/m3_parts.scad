// m3_parts.scad - A collection of things useful when developing with M3 fasteners

m3_screw_rad=3.4/2; // M3 screw hole radius
m3_screw_head_rad=5.9/2;    // Radius of the average M3 posi screw head
m3_screw_head_height=2.4;
m3_nut_max_width=6.4;     // M3 Nut from point to point.
m3_pillar_max_width=5.9;    // M3 pillar width, point to point
m3_nut_height=2.5;
m3_nut_min_width=5.8;  // Nut from flat to flat

// NEMA17 motors are *technically* M3 parts...
nema17_screw_sep=31;
nema17_collar_rad=22.5/2;   // The raised collar around the NEMA output shaft
nema17_face_len=42;         // Length of the square face of a NEMA17 ignoring bevels

// Cavity for M3 nut that goes into the top of things. Slight overshoot to avoid booleans
module m3_nut_cavity(ht=m3_nut_height) {
    translate([0,0,0.01]) cylinder(h=ht+0.01,r=m3_nut_max_width/2,$fn=6);
}

// A nut cavity for putting underneath things, with a nod to overhangs
module m3_nut_cavity_tapered() {
    // Cavity for m3 nut
    cylinder(h=m3_nut_height,r=m3_nut_max_width/2,$fn=6);
    translate([0,0,m3_nut_height])
        cylinder(h=1,r1=m3_nut_max_width/2,r2=m3_screw_rad*1.2,$fn=6);
}

// Nut  slot for M3 nut
module m3_nut_slot() {
    translate([-m3_nut_max_width/2,-m3_nut_min_width/2,0]) cube([m3_nut_max_width+100,m3_nut_min_width,m3_nut_height]);
}

// Cavity for an M3 screw and screw head of specified length.
// Points down. Uses octagons so that it can be printed horizontally
module  m3_screw_cavity(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m3_screw_rad*1.2,$fn=8);
    // Rotate to make hole sflats parallel to axes. Tiny shift to fix booleans
    rotate([0,0,360/16]) translate([0,0,-0.001])
        cylinder(h=10,r=m3_screw_head_rad*1.2,$fn=8);
}

// Octagonal hole for screw, no head, centred, length extends up and down
module  m3_screw_hole(screw_len) {
    rotate([180,0,360/16]) cylinder(h=screw_len,r=m3_screw_rad*1.2,$fn=8,center=true);
}

m3_thumbscrew_height=5;
m3_thumbscrew_rad=5;
// Thumbscrew with ridges. Screw head fits in top depression, nut on screw
// shaft holds it in place.
//  rad: Optional radius for thumbscrew knob (default 5, see above)
module m3_thumbscrew_knob(rad=m3_thumbscrew_rad) {
    m3_thumbscrew_ridges=floor(rad*3.2);
    difference() {
        union() {
            for (i=[0:m3_thumbscrew_ridges]) rotate([0,0,360/m3_thumbscrew_ridges*i])
                translate([rad,0,m3_thumbscrew_height/2])
                    cube([1,1,m3_thumbscrew_height],center=true);
            cylinder(h=m3_thumbscrew_height,r=rad);
        }
        translate([0,0,m3_thumbscrew_height-m3_screw_head_height]) m3_screw_cavity(m3_thumbscrew_height);
    }
}
