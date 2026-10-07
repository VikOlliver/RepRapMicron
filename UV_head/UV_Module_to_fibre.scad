// UV_Module_to_fibre.scad - Holds a 3W star UV module and a 125/9 fibre lead in close proximity
// Needs a couple of M3 fasteners. (c)2026 vik@olliver.family.gen.nz GPLv3 or later applies

include <../library/m3_parts.scad>

holder_int_rad=24/2;
holder_int_ht=12.5;
holder_expansion=0.4;
led_housing_rad=8.1/2;
wall=1.8;
inner_block_rad=led_housing_rad+wall;

$fn=64;

// A square fibre optic connector socket, height = very big.
plug_square=4.5;
tab_width=3.8;  // Dimensions of tab on side of optical plug.
tab_ht=1.6;
retaining_screw_sep=18.7;   // Distance M3 between screws

module fibre_socket() {
    verybig=999;
    translate([0,0,verybig/2]) {
        // Hole for fibre
        cube([plug_square,plug_square,verybig],center=true);
        // Slot for the tab on it.
        translate([0,0.01-(plug_square+tab_ht)/2,0]) cube([tab_width,tab_ht,verybig],center=true);
    }
}

module outer_with_fins() union() {
    // Ventilated outer
    difference() {
        cylinder(h=holder_int_ht,r=holder_int_rad);
        cylinder(h=holder_int_ht*3,r=holder_int_rad-wall,center=true);
    }
    // Support fins
    for (i=[0:3]) rotate([0,0,90*i]) translate([inner_block_rad-wall/4,-wall/2,holder_int_ht-wall*2]) hull() {
        cube([holder_int_rad-wall/2-inner_block_rad,wall,wall*2]);
        translate([0,0,-wall*3]) cube([0.01,wall,0.01]);
    }
    // M3 screw pillars
    translate([-retaining_screw_sep/2,0,0]) cylinder(h=holder_int_ht,r=m3_screw_rad+1);
    translate([retaining_screw_sep/2,0,0]) cylinder(h=holder_int_ht,r=m3_screw_rad+1);
}

// Bit that grips LED with a fibre socket in it.
difference() {
    union() {
        outer_with_fins();
        // Holder body
        cylinder(h=holder_int_ht,r=inner_block_rad);
    }
    // Hole for LED
    translate([0,0,-0.01]) cylinder(h=4.5,r=led_housing_rad);
    fibre_socket();
    // M3 screw holes
    translate([-retaining_screw_sep/2,0,0]) translate([0,0,holder_int_ht/2]) m3_screw_hole(holder_int_ht+1);
    translate([retaining_screw_sep/2,0,0]) translate([0,0,holder_int_ht/2]) m3_screw_hole(holder_int_ht+1);
}
