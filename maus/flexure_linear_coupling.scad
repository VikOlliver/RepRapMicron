// flexure_linear_coupling.scad - Attempt to make a coupling that allows linear movement of the shaft.

include <../library/m3_parts.scad>
include <../library/nema17lib.scad>

flex_tube_height=13;
flex_tube_spring_width=1.2;
max_gap=1;
flex_link_width=max_gap+flex_tube_spring_width;
wall=2;     // Minimal ridig wall
outer_radius=6;
spring_height=7;

// Basically a tube with spring_width walls
module flex_tube(radius,height=flex_tube_height) translate([0,0,height/2]) difference() {
    cylinder(h=height,r=radius+max_gap/2,center=true);
    cylinder(h=height+1,r=radius-flex_tube_spring_width/2,center=true);
}

module flex_quadrant(radius,height=flex_tube_height) {
    intersection() {
        union() {
            flex_tube(radius,height);
            flex_tube(radius+max_gap+flex_tube_spring_width,height);
        }
        translate([0,flex_tube_spring_width,-1]) cube([radius*2,radius*2,height+2]);
    }
    translate([radius,flex_tube_spring_width,0]) cube([flex_link_width,flex_tube_spring_width,height]);
    translate([0,radius-flex_link_width,0]) cube([flex_tube_spring_width,flex_link_width,height]);
    translate([0,radius+flex_link_width,0]) cube([flex_tube_spring_width,flex_link_width,height]);
}

// Stepper motor coupling.
// NOTE: Needs M3 screw with head filed down to 5.5mm dia and a nut driven all the way down.
nema_coupling_height=6;
top_radius=m3_nut_max_width/2+wall;
module nema_m3_coupling() {
    difference() {
        translate([0,0,-1]) cylinder(h=nema_coupling_height+1,r1=outer_radius+flex_link_width*2.25,r2=top_radius);
        // Cavity for nut, tapering, and a really tight fit
        translate([0,0,1]) cylinder(h=nema_coupling_height-0.99,r1=m3_nut_max_width/2-0.45,r2=m3_nut_max_width/2-0.1,$fn=6);
    }
}

// The outer cylinder
flex_tube(outer_radius+flex_link_width*2,height=spring_height+1);
// Fill with quadrants
for (i=[0:3]) {
    rotate([0,0,i*90]) flex_quadrant(outer_radius,height=spring_height);
}
// Central NEMA shaft hole
difference() {
    cylinder(h=spring_height,r=4.5);
    cylinder(h=100,r=2.5,center=true,$fn=32);
}

// Nut holding bit
translate([0,0,spring_height+2]) nema_m3_coupling();
