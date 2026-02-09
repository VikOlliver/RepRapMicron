// maus_pika.scad - RepRapMicron Maus Print In-place Kinematic Axes
// (C) 2026 vik@diamondage.co.nz Released under the GPLV3 or later.
// It is a Very Good Idea(TM) to keep the dimensions in Metriccano (10mm) units.
// Printed on Prusa Mk4, 0.2mm layers, 20% infill, 2 v shells, 5 h shells

// If we can stagger the flexures on the outer (X) frame, we can make it smaller in X.

include <../library/m3_parts.scad>
include <../library/metriccano.scad>
//include <../library/nema17lib.scad> Maybe use motors, even for direct drive, but  later...

version_string="PIKA V0.00";

flexure_thick=0.8;  // Width of a flexure beam, that's the very thin direction
flexure_width=5;      // Maximum desired flexing distance off centre
flexure_length=4;
flexure_height=1.2;   // Headroom given to a flexure

beam_thick=5;       // Thickness of a vertical structural beam
beam_flexure_side=flexure_width+1;  // Width of a beam on the side contacting the flexure
flexure_clearance=1.5;      // Any flexing part must miss by this much
horizontal_beam_width=7;    // Width of a horizontal beam, used to join flexure pairs.
lower_beam_height=10;       // Height of the lower hollow square bracing beams

structure_height=60;    // Maximum height of the total structure
frame_thick=5;              // Thickness of the notionally inflexible frame parts
// Dimensions of the box-like outer wall. If we can get x & y down to 120 that would be nice...
outer_wall_x=120;       
outer_wall_y=120;
box_wall=2;

// Sizings for the pair of flexures used everywhere
table_flexure_length=2*flexure_length+beam_thick;
table_flexure_pair_length=4*flexure_length+2*beam_thick+horizontal_beam_width;

// Dimensions of the lower square frame in the X flexures
outer_frame_x=outer_wall_x-2*box_wall-2*table_flexure_length+2*horizontal_beam_width;
outer_frame_y=outer_wall_y-2*box_wall-2*flexure_clearance;
outer_frame_stub=2*horizontal_beam_width+beam_flexure_side+2*flexure_clearance;

// Dimensions of the inner wall
inner_wall_x=outer_wall_x-4*table_flexure_length-2*box_wall;
inner_wall_y=outer_frame_y-2*flexure_clearance-2*horizontal_beam_width;
inner_wall_at_x=(outer_wall_x-inner_wall_x)/2;
inner_wall_at_y=box_wall+2*flexure_clearance+horizontal_beam_width;

// Dimensions of the central box that suspends the Y axis
muckedup_box_x=0;

// Size of the square light well
light_well_size=metriccano_unit/2+0.5;
// This plate fits on top of the stage and has cutouts for magnets in it
magnet_x=10;
magnet_y=30;
magnet_z=3;
led_wire_rad=3.2/2;      // Gap for UV LED wires
led_strip_width=8;        // Dimensions of UV LED strip
led_strip_length=20;
led_strip_height=1;
st_base_thick=1;
stage_holes_x=6;        // Number of holes in the stage
stage_holes_y=4;
// Work out stage dimensions to make maths easier
stage_size_x=(stage_holes_x-1)*metriccano_unit;
stage_size_y=(stage_holes_y-1)*metriccano_unit;


// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// Flexure used to join beams on the integrated XY Table
module horizontal_flexure() {
    translate([0,0,flexure_height-flexure_thick]) cube([flexure_length,flexure_width,flexure_thick]);
}

// A pair of the flexures used on the integrated XY Table X axis.
// These are staggered about X=0
module staggered_flexure_pair() {
        translate([0,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
        translate([flexure_length,0,0]) cube([beam_thick,beam_flexure_side,structure_height]);
        translate([flexure_length+beam_thick,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5]) horizontal_flexure();
    translate([0,beam_flexure_side+horizontal_beam_width+3*flexure_clearance,0]) {
        // Ascending flexure and beam
        translate([-flexure_length,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
        translate([-flexure_length-beam_thick,0,0])
            cube([beam_thick,beam_flexure_side,structure_height]);
        // Top flexure on far end
        translate([-2*flexure_length-beam_thick,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5])
            horizontal_flexure();
    }
}

// A pair of the flexures used on the integrated XY Table Y axis
module table_flexure_pair() {
    translate([0,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5]) horizontal_flexure();
    translate([flexure_length,0,0]) cube([beam_thick,beam_flexure_side,structure_height]);
    translate([flexure_length+beam_thick,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
    // Leave a gap for a central beam here
    // ...
    // Ascending flexure and beam
    translate([2*flexure_length+beam_thick+horizontal_beam_width,(beam_flexure_side-flexure_width)/2,0]) horizontal_flexure();
    translate([3*flexure_length+beam_thick+horizontal_beam_width,0,0])
        cube([beam_thick,beam_flexure_side,structure_height]);
    // Top flexure on far end
    translate([3*flexure_length+2*beam_thick+horizontal_beam_width,(beam_flexure_side-flexure_width)/2,structure_height-flexure_height-0.5])
        horizontal_flexure();
}

module x_flexure_pair() {
    translate([0,horizontal_beam_width+flexure_clearance,0]) staggered_flexure_pair();
    translate([outer_frame_x-2*horizontal_beam_width,horizontal_beam_width+flexure_clearance,0])
       scale([-1,1,1])  staggered_flexure_pair();
}

module y_flexure_pair() {
        translate([beam_flexure_side,0,0]) rotate([0,0,90]) table_flexure_pair();
        translate([beam_flexure_side,inner_wall_y-table_flexure_pair_length-2*box_wall,0]) rotate([0,0,90]) table_flexure_pair();
}

// The outside box to which all the mounting hardware is attached
module outside_box() {
    difference() {
    cube([outer_wall_x,outer_wall_y,structure_height]);
    // Hollow it out
    translate([box_wall,box_wall,-1])
        cube([outer_wall_x-2*box_wall,outer_wall_y-2*box_wall,structure_height*2]);    
    }
}

// The inside box containing the stage support
module inside_box() {
    difference() {
    cube([inner_wall_x,inner_wall_y,structure_height]);
    // Hollow it out
    translate([box_wall,box_wall,-1])
        cube([inner_wall_x-2*box_wall,inner_wall_y-2*box_wall,structure_height*2]);    
    }
}

%outside_box();
translate([box_wall,box_wall+flexure_clearance,0]) {
    // The X axis flexures onna square
    translate([table_flexure_length,0,0]) x_flexure_pair();
    translate([table_flexure_length,outer_frame_y,0]) 
        scale([1,-1,1]) x_flexure_pair();


    // Make the outer hollow square bracing beam with staggered edges
    translate([(outer_wall_x-outer_frame_x)/2-box_wall,0,0]) {
        difference() {
            // Square frame
            cube([outer_frame_x,outer_frame_y,lower_beam_height]);
            // Hollow it out
            translate([horizontal_beam_width,horizontal_beam_width,-1])
                cube([outer_frame_x-2*horizontal_beam_width,outer_frame_y-2*horizontal_beam_width,lower_beam_height*2]);
            // Cut away two sides where we stagger it
            translate([-outer_frame_x/2,outer_frame_stub,-1])
                cube([outer_frame_x*2,outer_frame_y-2*outer_frame_stub,lower_beam_height*2]);
        }
        // Kink back in towards the centre
        translate([horizontal_beam_width,outer_frame_stub-horizontal_beam_width,0])
            cube([horizontal_beam_width,outer_frame_y-2*outer_frame_stub+2*horizontal_beam_width,lower_beam_height]);
        translate([outer_frame_x-2*horizontal_beam_width,outer_frame_stub-horizontal_beam_width,0])
            cube([horizontal_beam_width,outer_frame_y-2*outer_frame_stub+2*horizontal_beam_width,lower_beam_height]);
    }
}

translate([inner_wall_at_x,inner_wall_at_y,0]) {
   %inside_box();
    translate([box_wall+flexure_clearance,box_wall,0]) y_flexure_pair();
    translate([inner_wall_x-box_wall-flexure_clearance-beam_flexure_side,box_wall,0]) y_flexure_pair();
    // Two beams linking the pairs of flexures
    translate([box_wall+flexure_clearance,table_flexure_length+box_wall,0])
        cube([inner_wall_x-2*box_wall-2*flexure_clearance,horizontal_beam_width,lower_beam_height]);
    translate([box_wall+flexure_clearance,inner_wall_y-horizontal_beam_width-table_flexure_length-box_wall,0])
        cube([inner_wall_x-2*box_wall-2*flexure_clearance,horizontal_beam_width,lower_beam_height]);
    // Two beams linking the above linked paris, looking a bit like ][
    translate([box_wall+2*flexure_clearance+beam_flexure_side,table_flexure_length+box_wall,0])
        cube([horizontal_beam_width,inner_wall_y-2*box_wall-table_flexure_pair_length,lower_beam_height]);
    translate([inner_wall_x-box_wall-2*flexure_clearance-beam_flexure_side-horizontal_beam_width
    ,table_flexure_length+box_wall,0])
        cube([horizontal_beam_width,inner_wall_y-2*box_wall-table_flexure_pair_length,lower_beam_height]);
}

centre_platform_x=inner_wall_x-2*box_wall-2*flexure_clearance;
centre_platform_y=inner_wall_y-2*box_wall-2*table_flexure_pair_length;

// The pillar that rises up through the middle and holds the stage (or anchor bracket for it)
translate([outer_wall_x/2,outer_wall_y/2,0]) {
    // The bit the actual Stage will attach to
    translate([-metriccano_unit*1.5,-metriccano_unit*2.5,structure_height]) metriccano_plate(4,6);
    // 45 degree prism with the flat on top . Should be easy-ish to print suspended
    translate([0,0,structure_height]) hull() {
        cube([centre_platform_x,centre_platform_y,0.01],center=true);
        translate([0,0,-centre_platform_y*sqrt(2)/2]) cube([centre_platform_x,0.01,0.01],center=true);
    }
    // Centre pillar. We use beam_flexure_side as it is a known robust vertical support.
    translate([0,0,structure_height/2]) {
        cube([beam_flexure_side,centre_platform_y,structure_height],center=true);
        // Couple of end pillars
        translate([beam_flexure_side/2-centre_platform_x/2,0,0]) cube([beam_flexure_side,centre_platform_y,structure_height],center=true);
        translate([-beam_flexure_side/2+centre_platform_x/2,0,0]) cube([beam_flexure_side,centre_platform_y,structure_height],center=true);
    }
}
