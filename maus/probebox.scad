// probebox.scad - Box for protecting a probe
// (c) 2025 vik@diamondage.co.nz, GPL V3 or later applies

include <../library/m3_parts.scad>

corner_rad=5;
box_side=50;
box_interior_width=30;
box_inside_height=18;
anchor_hole_y=-3-box_interior_width/2;
// Radius of the lug that supports the probe body
lug_rad=6;
// XY placement of corners and corner holes
corner_displacement=box_side/2-corner_rad;

module box_section(height) {
    difference() {
        // The meaty body of the box section
        hull() {
            translate([corner_displacement,corner_displacement,0])
                cylinder(h=height,r=corner_rad,$fn=30);
            translate([-corner_displacement,corner_displacement,0])
                cylinder(h=height,r=corner_rad,$fn=30);
            translate([corner_displacement,-corner_displacement,0])
                cylinder(h=height,r=corner_rad,$fn=30);
            translate([-corner_displacement,-corner_displacement,0])
                cylinder(h=height,r=corner_rad,$fn=30);
        }
        // Holes in the corners
        translate([corner_displacement,corner_displacement,0])
            cylinder(h=height*3,r=m3_screw_rad,center=true,$fn=30);
        translate([-corner_displacement,corner_displacement,0])
            cylinder(h=height*3,r=m3_screw_rad,center=true,$fn=30);
        translate([corner_displacement,-corner_displacement,0])
            cylinder(h=height*3,r=m3_screw_rad,center=true,$fn=30);
        translate([-corner_displacement,-corner_displacement,0])
            cylinder(h=height*3,r=m3_screw_rad,center=true,$fn=30);
    }
}

// A slot to accept an M3 nut, tilted at 45 degrees so we can tuck it into the corner.
// Rounded corners. 60 degree rotation makes the slots miss the rounded box corners allowing no support.
module nut_slot()
    translate([-corner_displacement,-corner_displacement,0])
        rotate([0,0,60]) translate([1-m3_nut_min_width/2,1-m3_nut_max_width/2,-m3_nut_height/2])
            minkowski() {
                cube([m3_nut_min_width-2,20-2,m3_nut_height-1]);
                cylinder(h=1,r=1,$fn=16,center=true);
            }

// 4 nut slots to make a layer
module nut_slots() {
    nut_slot();
    rotate([0,0,90]) nut_slot();
    rotate([0,0,-90]) nut_slot();
    rotate([0,0,180]) nut_slot();
}

// Box without bottom or lid, but with hole to anchor probe by its screw
difference() {
    union() {
        // Make a hole with a lug inside
        difference() {
            // Start with a chunk o' box
            box_section(box_inside_height);
            // Chop out the interior
            cube([box_interior_width,box_interior_width,box_inside_height*3],center=true);
        }
        translate([0,anchor_hole_y,0]) cylinder(h=6,r=lug_rad,$fn=30);
    }
    translate([0,anchor_hole_y,0]) {
        // Put in an anchor screw hole
        cylinder(h=box_inside_height*3,r=m3_screw_rad,center=true,$fn=30);
        // Carve a cavity for the nut
        translate([0,0,3])
            cylinder(h=box_inside_height*3,r=m3_nut_max_width/2+0.1,$fn=30);
        // A cavity for the probe body
        translate([0,0,6])
            cylinder(h=box_inside_height*3,r=lug_rad,$fn=30);
        // Holes for tweezers to get a grip
        translate([0,0,6+box_inside_height/2])
            cube([lug_rad*2+6,3,box_inside_height],center=true);
    }
    // Holes for lower nuts
    translate([0,0,4]) nut_slots();
    // Holes for upper nuts, staggered for artistic effect.
    translate([0,0,box_inside_height-4]) scale([-1,1,1]) nut_slots();
}


// A lid if you need it, though these look so much cooler lasercut.
// box_section(3);