// maus_axis_driver.scad - RepRapMicron motion stage
// (c)2025 vik@diamondage.co.nz, released under the terms of the GPL V3 or later
// Prototype Linear Maus Axis Diver, non-functional
// Tries to use a pantograph-like mechanism, paralleled up to provide stable
// drive, anchor, and effector ends.
// This contains much unsorted/unnecessary fluff.
//
// UNDER EARLY DEVELOPMENT
//
// Note: It is a Very Good Idea(TM) to keep all the mounting and fixing points
// close to 10mm centres. If necessary, tweak angles, ratios, and arm lengths to do this.

version_string="MAUS V0.05";

include <../library/m3_parts.scad>
include <../library/nema17lib.scad>
include <../library/metriccano.scad>

flexure_width=4;
flexure_length=2.5;
flexure_height=1.0;     // Thickness of the flexure block including footings
flexure_thickness=0.6;  // Thickness of the actual flexure part
flexure_tab_length=flexure_length+2;    // Distance between two attachment zones.
vertical_flexure_length=8;
vertical_flexure_height=6;
vertical_flexure_width=8;   // Width of the anchor block
vertical_flexure_thick=8.2; // Width of the actual flexing bit

// Used to fiddle flexures. Just over one layer...
layer_height=0.21;
wall=2;                         // Arbitrary rigid wall thickness

reduction_ratio=0.685;    //  Amount we want to reduce the movement by

arm_angle=55.2;   // Angle of the paralellogram. Zero is flat.

// Length of a parallelogram main arm
pll_main_arm_length=71;
//pll_main_arm_at_45=sqrt(pll_main_arm_length*pll_main_arm_length/2);
pll_main_arm_x=pll_main_arm_length*cos(arm_angle);
pll_main_arm_y=pll_main_arm_length*sin(arm_angle);
pll_main_arm_at_45=pll_main_arm_x;

pll_beam_end_flat_height=flexure_height+1.5;
pll_beam_x=7;  // Parallelogram beam width along the X axis
pll_beam_y=flexure_width+2;
pll_platform_beam_length=metriccano_unit;
// Bottom beam is higher than top beam as it has to fit between moving flexures
pll_top_beam_height=3;
pll_bottom_beam_height=10;
// Distance between the two most distant flexures
pll_flexure_to_flexure=pll_main_arm_x*2+flexure_tab_length+pll_platform_beam_length;

echo("End fixing separation =",pll_flexure_to_flexure+flexure_tab_length+metriccano_unit);

pll_arm_a_length=pll_main_arm_length*(1-reduction_ratio);
pll_arm_a_x=pll_arm_a_length*cos(arm_angle);
pll_arm_a_y=pll_arm_a_length*sin(arm_angle);
pll_arm_b_length=pll_main_arm_length*reduction_ratio;
pll_arm_b_x=pll_arm_b_length*cos(arm_angle);
pll_arm_b_y=pll_arm_b_length*sin(arm_angle);


// Distance from frame center to frame center (leave gap so they dont rub).
pll_frame_centres=metriccano_nut_max_width+2;
// Calculate the gap between frames
pll_frame_spacing=pll_frame_centres-pll_beam_y;

// A flexure joint for printing it on the surface of the print bed. Footings extend 1mm.
// "flat" will print without an undercut
module flexure_tab(flat=false) difference() {
    translate([0,0,flexure_height/2]) cube([flexure_tab_length+2,flexure_width,flexure_height],center=true);
    if (flat) {
        // Hollow just the top of the flexure
        translate([0,0,flexure_height]) 
            cube([flexure_length*0.6,flexure_width*3,flexure_thickness*2],center=true);    
    } else {
        // Hollow the top of the flexure
        translate([0,0,flexure_height+layer_height]) 
            cube([flexure_length*0.6,flexure_width*3,flexure_thickness*2],center=true);    
        // Undercut the flexure so it does not touch print bed
        cube([flexure_length*0.6,flexure_width*3,layer_height*2],center=true);
    }
}

// A flexure join that will be printed suspended in air
module flexure_tab_unsupported() difference() {
    translate([0,0,flexure_height/2]) cube([flexure_tab_length+1,flexure_width,flexure_height],center=true);
    // Scalop the top of the flexure
    translate([0,0,flexure_height]) cube([flexure_length*0.6,flexure_width*3,flexure_height],center=true);
}

// Flat end of a beam, levelled on Z=0, centred on X=Y=0
// Made smaller for the top layer
module pll_beam_end(l=pll_beam_end_flat_height) {
    translate([-pll_beam_x/2,-pll_beam_y/2,0])
        cube([pll_beam_x,pll_beam_y,l]);
}

module pll_long_arm() {
    pll_beam_end();
    hull() {
        translate([0,0,pll_beam_end_flat_height]) pll_beam_end();
    translate([pll_main_arm_x,0,pll_main_arm_y]) pll_beam_end();
    }
}

module pll_arm_a() {
    pll_beam_end();
    hull() {
        translate([0,0,pll_beam_end_flat_height]) pll_beam_end();
    translate([pll_arm_a_x,0,pll_arm_a_y]) pll_beam_end();
    }
}

// Create an arm with a flexure on each end between (0,0) and (x,y).
// Reverse will make the flexures point in opposite directions.
// We may need to extend the base of the arm away from the Drive Screw
// or the arm will collide with the upper_nut_bar then it is driven down.
module pll_flexure_arm(x,y,reverse=false,extend_base=0)  {    
    // First flexure, placed on 0,0
    flexure_tab();
    if (reverse) hull() {
        // Join up the extension so that it is alwaus a solid baem.
        translate([(extend_base+pll_beam_x+flexure_tab_length)/2,0,0]) pll_beam_end();
        translate([(pll_beam_x+flexure_tab_length)/2,0,0]) pll_beam_end(metriccano_unit/2);
    }
    else
        translate([(-pll_beam_x-flexure_tab_length)/2,0,0]) pll_beam_end();
    // The beam bit
    hull() {
        if (reverse) {
            translate([(extend_base+pll_beam_x+flexure_tab_length)/2,0,pll_beam_end_flat_height]) pll_beam_end();
            translate([x+(-pll_beam_x-flexure_tab_length)/2,0,y]) pll_beam_end(flexure_height);
        } else {
            translate([(-pll_beam_x-flexure_tab_length)/2,0,pll_beam_end_flat_height]) pll_beam_end();
            translate([x+(-pll_beam_x-flexure_tab_length)/2,0,y]) pll_beam_end(flexure_height);
        }
    }
    // Second flexure  placed on the mark
  
  translate([x,0,y]) flexure_tab(flat=true);
}

// Main arm wiht a kink where the centre flexure goes
module bent_pll_arm(ratio,extend_base=0) {
    pll_flexure_arm(pll_main_arm_x*(1-ratio),pll_main_arm_y*(1-ratio),true,extend_base);
    translate([pll_main_arm_x*(1-ratio),0,pll_main_arm_y*(1-ratio)])
        pll_flexure_arm(pll_main_arm_x*ratio,pll_main_arm_y*ratio);
}

// Pantograph arm with platforms in the middle and at each end
module centre_pll_arm() {
    // The -X arm
    bent_pll_arm(reduction_ratio) ;
    // The +X arm, with Arm B and beam platform on it.
    translate([pll_main_arm_x*2+pll_platform_beam_length+flexure_tab_length,0,0])
        rotate([0,0,180]) {
            // Main arm. Extend the base out to avoid collision with upper_nut_bar
            bent_pll_arm(1-reduction_ratio,extend_base=8);
            // Arm B
            translate([pll_arm_b_x*2,0,0]) rotate([0,0,180])
                pll_flexure_arm(pll_arm_b_x,pll_arm_b_y,true);
            translate([pll_arm_b_x*2+(flexure_tab_length+pll_platform_beam_length)/2,0,pll_bottom_beam_height/2])
                cube([pll_platform_beam_length,pll_beam_y,pll_bottom_beam_height],center=true);
    }
            
    // Arm A
    translate([pll_arm_a_x*2,0,0]) rotate([0,0,180])
        pll_flexure_arm(pll_arm_a_x,pll_arm_a_y,true);
        
    // The top beam. Make sure it rests on top of the flexure...
    translate([pll_main_arm_x+pll_platform_beam_length/2+flexure_tab_length/2,0,pll_main_arm_y+pll_top_beam_height/2]) 
        cube([pll_platform_beam_length,flexure_width,pll_top_beam_height],center=true);
}

// Tags to connect to flexures Heads off in -X, -Y and right end is at X=0.
module fixed_arm_flexure_tag() {
    // This bit goes on the flexure
    hull() {
        translate([1,(metriccano_unit-flexure_width*1.5)/2,flexure_height/2])
            cube([1,flexure_width,flexure_height],center=true);
        // This bit hides inside the metriccano strip
        translate([0.2-pll_platform_beam_length+flexure_tab_length/2+metriccano_screw_rad,0,metriccano_unit/4])
            cube([0.1,metriccano_unit/2,metriccano_unit/2],center=true);
    }
}

// Create an anchor for the end where the centre points is recessed
module anchor_pointed_in() translate([metriccano_unit/2,0,0]) {
    difference() {
        union() {
            // Add a cavity for the drive nut and tab that in theory will hit the limit switch
            translate([-metriccano_unit,0,0]) rotate([0,0,180]) 
                // Make sure the screw hole is oversize so it never clips the drive screw
                difference() {
                    metriccano_strip_flatend(1,nutted=true,extend_end=metriccano_unit*2);
                    cylinder(h=metriccano_unit*2,r=2,center=true,$fn=32);
                }
            // Lugs to reach flexures (extends less than a Metriccano unit to clear framework)
            translate([0,-metriccano_unit/2-pll_frame_spacing,metriccano_plate_height/2])
                cube([metriccano_unit,pll_frame_centres+1,metriccano_plate_height],center=true);
            translate([0,metriccano_unit/2+pll_frame_spacing,metriccano_plate_height/2])
                cube([metriccano_unit,pll_frame_centres+1,metriccano_plate_height],center=true);
        }
    }
}

// An anchor where the centre flexure protrudes, aligned on X=0
// Anchor holes in -X direction, nuts underneath.
module anchor_pointed_out() union() {
    // U-Shaped block with nut holes underneath
    difference() {
        translate([-metriccano_unit,0,metriccano_plate_height/2])
            cube([metriccano_unit*2,metriccano_unit*3,metriccano_plate_height],center=true);
            // Notch
            cube([metriccano_unit*2,metriccano_unit,metriccano_unit*2],center=true);
            // Nutted holes underneath
            for (x=[0:1]) for (y=[-1:1])
            translate([-metriccano_unit/2-metriccano_unit*x,metriccano_unit*y,metriccano_nut_height]) {
                rotate([180,0,0]) metriccano_nut_cavity_tapered(captive=true,inverted=true);
                metriccano_screw_hole();
          }
    }
 }
 
 bb_hook_x=3;
 bb_hook_y=4;
 bb_hook_z=5;
 // Wee hooks for attaching anit-backlash bands to flexures. Extends in -Y, face on 0
 module backlash_band_hook() {
        // Body of hook
        translate([0,-bb_hook_y/2,bb_hook_z/2]) difference() {
            cube([bb_hook_x,bb_hook_y,bb_hook_z],center=true);
            // Cutout for band. Place on bottom of hook block, slightly raised
            translate([0,0.5,bb_hook_y*0.1-bb_hook_z/2]) {
                // Double height for more band room...
                rotate([0,90,0]) rotate([0,0,180/8])
                    cylinder(h=bb_hook_x*3,r=bb_hook_y*0.5,$fn=8,center=true);
                translate([0,0,bb_hook_y*0.25]) rotate([0,90,0]) rotate([0,0,180/8])
                    cylinder(h=bb_hook_x*3,r=bb_hook_y*0.5,$fn=8,center=true);
            }
        }
 }
 
 side_beam_length=metriccano_unit*11;
 side_beam_width=metriccano_unit;
 side_beam_height=metriccano_unit;
 // One on each side, screws to motor mount
 module side_beam() {
     //%metriccano_square_strip(11);
     difference() {
         union() {
             // Main beam
             translate([-metriccano_unit/2,-side_beam_width/2,0])
                cube([side_beam_length,side_beam_width,side_beam_height]);
             // Lugs to fasten to motor bracket
             translate([metriccano_unit*7,-metriccano_unit,0]) 
                rotate([0,0,180]) metriccano_tab_module(3);
         }
         // Attachment position for Limit Switch bracket on end flat of beam
         translate([side_beam_length-metriccano_unit,0,side_beam_height/2]) {
            rotate([0,90,0]) metriccano_screw_hole();
            translate([-metriccano_nut_height,0,0]) rotate([0,-90,0]) metriccano_nut_slot();
         }
         // Hole to mount Nut Bars, attach to XY Frame etc.
         for (i=[0:8])
            translate([side_beam_length-metriccano_unit*(i+3),0,side_beam_height/2])
                metriccano_screw_hole();
         // Attachment points for Z Flexure
         translate([0,metriccano_unit/2,metriccano_unit/2])
            rotate([90,0,0]) {
                metriccano_nut_cavity_tapered(captive=true);
                metriccano_screw_hole();
            }
         translate([metriccano_unit,metriccano_unit/2,metriccano_unit/2])
            rotate([90,0,0]) {
                metriccano_nut_cavity_tapered(captive=true);
                metriccano_screw_hole();
            }
         // Cutout to stop the anti-backlash band hook rubbing if it distorts under load
         translate([pll_flexure_to_flexure-metriccano_unit*1.5-1.5,metriccano_unit-2.5,0])
                rotate([0,0,180/8])
                    cylinder(h=metriccano_unit*3,r=metriccano_unit/2,$fn=8,center=true);
    }
 }
// Three parallelogram arms with platfroms between them.
module frame_trio() {
    // Trio of pll frames
    translate([0,pll_frame_centres,0]) centre_pll_arm();
    translate([-pll_platform_beam_length,0,0]) centre_pll_arm();
    translate([0,-pll_frame_centres,0]) centre_pll_arm();

    // Join the bottom beams
    translate([pll_arm_a_x*2+(flexure_tab_length)/2,0,0]) {
        translate([0,0,pll_bottom_beam_height-2])
             rotate([90,0,0]) scale([0.8,1,1]) rotate([0,0,30]) cylinder(h=pll_beam_y*3+pll_frame_spacing*2,r=4,center=true,$fn=3);
        // Lugs on the bottom beams. Must not engage too far into side beams.
        translate([pll_platform_beam_length/2-metriccano_unit/2,-metriccano_unit*1.6,0]) {
            cube([metriccano_unit,metriccano_unit,metriccano_unit]);
        }
        translate([pll_platform_beam_length/2-metriccano_unit/2,metriccano_unit*0.6,0]) {
            cube([metriccano_unit,metriccano_unit,metriccano_unit]);
        }
    }

    // Join the top beams.
    translate([pll_flexure_to_flexure/2,
        0,pll_main_arm_y+metriccano_plate_height/2+pll_top_beam_height]) {
            // Start by linking the two outer ones.
           cube([pll_platform_beam_length,2*pll_frame_centres+flexure_width,metriccano_plate_height],center=true);
           // Now put a plate on the centre top beam.
            hull() {
               // This stops the slicer slicing the beam and the link to the centre simultaneously.
               translate([-pll_platform_beam_length,0,-metriccano_plate_height/4-2])
                    cube([pll_platform_beam_length,flexure_width,2],center=true);
                // This bit sticks on the vertical face of the bridge
                translate([-pll_platform_beam_length/2,0,0])
                    cube([2,flexure_width,metriccano_plate_height],center=true);
            }
    }

    // Create a base to anchor the anchored end
    translate([pll_flexure_to_flexure+flexure_tab_length/2,0,0]) {
        anchor_pointed_in();
        // Hooks for anti-backlash
        translate([-flexure_tab_length-bb_hook_x/2,-pll_beam_y*1.5-pll_frame_spacing,0])
            backlash_band_hook();
        translate([-flexure_tab_length-bb_hook_x/2,pll_beam_y*1.5+pll_frame_spacing,0])
            rotate([0,0,180]) backlash_band_hook();
    }
    // Anchor at X=0
    translate([-flexure_tab_length/2,0,0]) anchor_pointed_out();
    // Side brackets. Flip second one to a mirror image
    translate([-pll_platform_beam_length-flexure_tab_length/2+metriccano_unit*3-metriccano_unit/2,-metriccano_unit*2,0]) {
        side_beam();
        // Version legend
        translate([28,-side_beam_width/2,side_beam_height/2])
            rotate([90,0,0])version_text() ;
    }
    translate([-pll_platform_beam_length-flexure_tab_length/2+metriccano_unit*3-metriccano_unit/2,metriccano_unit*2,0]) scale([1,-1,1]) side_beam();
}


// NEMA17 mount, with plenty of fixing holes for experimentation
// This is *NOT* the motor mount used on the final axis.
module nema17_horizontal_mount() {
    difference() {
        union() {
            // Create something like a metriccano plate, slightly wider than NEMA17
            translate([0,0,metriccano_unit/2])
                cube([metriccano_unit*5,7*metriccano_unit,metriccano_unit],center=true);
            // Add two stacks of mounting blocks
            translate([-metriccano_unit*2,-metriccano_unit*3,0]) {
                // Square strips, rotated so nut slots are visible
                for (i=[1:5])
                    translate([0,metriccano_unit/2,metriccano_unit/2+metriccano_unit*i])
                        rotate([90,0,0]) metriccano_square_strip(5);
            }
            translate([-metriccano_unit*2,metriccano_unit*2,0]) {
                // Square strips, rotated so nut slots are visible
                for (i=[1:5])
                    translate([0,metriccano_unit/2,metriccano_unit/2+metriccano_unit*i])
                        rotate([-90,0,0]) metriccano_square_strip(5);
            }
            // Attachment point for adapter to V0.04 frame
            translate([metriccano_unit*3.5,metriccano_unit*3,metriccano_unit/2])
                rotate([0,-90,0]) metriccano_square_strip(6);
            translate([metriccano_unit*3.5,metriccano_unit*-3,metriccano_unit/2])
                rotate([0,-90,0]) metriccano_square_strip(6);
        }
        // Smack holes in mounting plate
        // Screw holes
        translate([nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
        translate([-nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
        translate([nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
        translate([-nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=metriccano_unit*3,r=m3_screw_rad,$fn=16,center=true);
         // Collar hole
        cylinder(h=metriccano_unit*3,r=nema17_collar_rad,center=true);
    }
}

nut_bar_length=metriccano_unit*4;
nut_bar_width=10;
nut_bar_height=11;  // 1mm of this is actually on top of the bearing block arms, so the block will be thinner
nut_bar_arm_height=nut_bar_height+metriccano_unit;

// Basic shape of the beam that holds the top bearing nut
module nut_bar_body() {
    hull() {
        translate([0,nut_bar_length/2,0]) cylinder(h=nut_bar_height-1,r=nut_bar_width/2);
        translate([0,-nut_bar_length/2,0]) cylinder(h=nut_bar_height-1,r=nut_bar_width/2);
    }
}

// Groves to hold tension bands on top of nut bar (or a booster)
module tension_band_grooves() {
    translate([nut_bar_width,metriccano_unit*1.2,0]) rotate([0,45,0])
        cylinder(h=nut_bar_height*2,r=nut_bar_width*0.6,center=true,$fn=32);
    translate([nut_bar_width,-metriccano_unit*1.2,0]) rotate([0,45,0])
        cylinder(h=nut_bar_height*2,r=nut_bar_width*0.6,center=true,$fn=32);
    translate([-nut_bar_width,metriccano_unit*1.2,0]) rotate([0,-45,0])
        cylinder(h=nut_bar_height*2,r=nut_bar_width*0.6,center=true,$fn=32);
    translate([-nut_bar_width,-metriccano_unit*1.2,0]) rotate([0,-45,0])
        cylinder(h=nut_bar_height*2,r=nut_bar_width*0.6,center=true,$fn=32);
}

// Block across the top of the supports that holds the bearing. Bearing is an M3 nut drilled out to 3mm.
// Made removable for ease of assembly
module upper_nut_bar() {
    // Rounded top bar with bearing hole in it
    difference() {
        union() {
            // Bearing block
            nut_bar_body();
            // Support arms
                translate([0,nut_bar_length/2,0]) cylinder(h=nut_bar_arm_height,r=nut_bar_width/2);
                translate([0,-nut_bar_length/2,0]) cylinder(h=nut_bar_arm_height,r=nut_bar_width/2);
        }
            
        // Bearing hole
        metriccano_screw_hole(nut_bar_height*4);
        // Bearing nut, slightly proud to avoid booleans, rotated to maintain beam strength, undersize
        translate([0,0,nut_bar_height-0.999-metriccano_nut_height])
            rotate([0,0,30]) scale([0.99,0.99,1]) metriccano_nut_cavity_tapered(true);
        // Anchor screw holes, recessed, pointed up
        translate([0,-nut_bar_length/2,metriccano_screw_head_height])
            scale([1,1,-1]) metriccano_screw_cavity(nut_bar_arm_height*4,inverted=true);
        translate([0,nut_bar_length/2,metriccano_screw_head_height])
            scale([1,1,-1]) metriccano_screw_cavity(nut_bar_arm_height*4,inverted=true);
         
        // Groves to hold tension bands
        tension_band_grooves();
    }
}


//  Tension Band Booster. Used to stretch anti-backlash bands if needed.
module tension_band_booster() {
    // Copy of the Nut bar beam with holes punched in for screw head access
    difference() {
        nut_bar_body();
        // Screw access holes (this is not an insult)
        translate([0,-nut_bar_length/2,metriccano_screw_head_height]) scale([1,1,-1])
            cylinder(h=nut_bar_height*3,r=m3_screw_head_rad+0.5,center=true);
        translate([0,nut_bar_length/2,metriccano_screw_head_height]) scale([1,1,-1])
            cylinder(h=nut_bar_height*3,r=m3_screw_head_rad+0.5,center=true);
        tension_band_grooves();
        // Clearance hole in case anyone finds a particularly long M3 screw
        cylinder(h=nut_bar_height*3,r=2,center=true,$fn=32);
    }
    // Use the tension band grooves to make locating lugs for the Tension Band Booster
    translate([0,0,nut_bar_height-1]) intersection() {
        nut_bar_body();
        tension_band_grooves();
    }
}


// 0.6mm thick text, 5mm tall, vertical, flat on XY plane
module version_text() {
    translate([0,0,-0.3]) linear_extrude(0.6) {
        text(version_string, size = 4, halign = "center", valign = "center", $fn = 16);
    }
}

// Selection of holes that line up with the pillars supporting
// the complete axis over the motor
// If "nutted" put captive nut cavities underneath (used for motor mount)
module pillar_screw_holes(nutted=false) {
    translate([metriccano_unit,-3*metriccano_unit,-0.001]) {
        cylinder(h=axis_motor_pillar_height*3,r=metriccano_screw_rad,$fn=16,center=true);
        if (nutted) metriccano_nut_cavity_tapered(captive=true,inverted=true) ;
    }
    translate([metriccano_unit,3*metriccano_unit,-0.001]) {
        cylinder(h=axis_motor_pillar_height*3,r=metriccano_screw_rad,$fn=16,center=true);
        if (nutted) metriccano_nut_cavity_tapered(captive=true,inverted=true) ;
    }
    translate([2*metriccano_unit,3*metriccano_unit,-0.001]) {
        cylinder(h=axis_motor_pillar_height*3,r=metriccano_screw_rad,$fn=16,center=true);
        if (nutted) metriccano_nut_cavity_tapered(captive=true,inverted=true) ;
    }
    translate([2*metriccano_unit,-3*metriccano_unit,-0.001]) {
        cylinder(h=axis_motor_pillar_height*3,r=metriccano_screw_rad,$fn=16,center=true);
        if (nutted) metriccano_nut_cavity_tapered(captive=true,inverted=true) ;
    }
}

// Mounting plate for a NEMA17 motor with rounded corners,
// Extended width for metriccano mounting
// nema_late_thick - Thickness of NEMA mounting plate
// nema_corner_rad - radius of rounded corners
module nema17_plate(nema_plate_thick=5,nema_corner_rad=2) difference() {
    rad_loc=(5*metriccano_unit-nema_corner_rad)/2-1;
    hull() {
        // +Y side
        translate([rad_loc,rad_loc+metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([-rad_loc,rad_loc/2+metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        // _Y side
        translate([rad_loc,-rad_loc-metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([-rad_loc,-rad_loc/2-metriccano_unit,0]) cylinder(h=nema_plate_thick,r=nema_corner_rad);
        // Central markers where we start narrowing the end down
        translate([0,-rad_loc-metriccano_unit,0])
            cylinder(h=nema_plate_thick,r=nema_corner_rad);
        translate([0,rad_loc+metriccano_unit,0])
            cylinder(h=nema_plate_thick,r=nema_corner_rad);

    }
    // NEMA17 Screw holes
    translate([nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([-nema17_screw_sep/2,nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
    translate([-nema17_screw_sep/2,-nema17_screw_sep/2,0]) cylinder(h=nema_plate_thick*3,r=m3_screw_rad,$fn=16,center=true);
     // Collar hole
    cylinder(h=nema_plate_thick*3,r=nema17_collar_rad,center=true);
    // Relief holes for over-travel of pillar screws
    pillar_screw_holes();
}

// A NEMA17 plate with nutted Metriccano mounting holes, pillars to prop up the axis flexure mechanism,
// A separate spacer is used under the motor to accomodate differing shaft lengths
axis_motor_pillar_height=35;
motor_pillar_spacing=6*metriccano_unit;     // Pillar holes, centre to centre
motor_base_thick=10;

// This goes on the side of the pillar assembly to allow attachment to the frame.
mb_height=axis_motor_pillar_height+motor_base_thick;    // Total height of motor bracket
mb_height_in_holes=floor(mb_height/metriccano_unit);
mb_length_in_holes=3;

// A pair of these are  used to attach the motor pillar assembly to the frame rigidly.
module motor_mount_side_attachment() {
    // Metriccano mounting strips
    for (i=[0:mb_length_in_holes-1])
            translate([metriccano_unit*(i+0.5),0,mb_height-metriccano_unit/2])
                rotate([0,90,0]) metriccano_square_strip(mb_height_in_holes);
    // Block making up space for non-metriccano unit gap.
    // Mostly there to print without support.
    translate ([metriccano_unit/2,-metriccano_unit/2,0]) difference() {
        cube([metriccano_unit*mb_length_in_holes,metriccano_unit,5]);
        for (i=[0:mb_length_in_holes-1])
            translate([metriccano_unit*(i+0.5),metriccano_unit/2,0])
                metriccano_screw_hole();
        }
}

// These holes should line up with the side attachments to allow through-holes
// for fastening to the frame. Head in the -Z direction
module motor_mount_side_holes() {
    // Use one less hole so we don't drill into the base plate
    for (i=[0:mb_height_in_holes-2])
        translate([0,0,-metriccano_unit*i])
            rotate([0,-90,0]) metriccano_screw_cavity(mb_length_in_holes*2*metriccano_unit);
}

// The assembled motor bracket, pillar, and attachment points.
module axis_motor_pillar_assy() {
    difference() {
        union() {
            nema17_plate(motor_base_thick);
            // Mounting hole pillars, joined for strength
            hull() {
                // Screw pillars
                translate([metriccano_unit,-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                translate([2*metriccano_unit,-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                // Reinforcement
                translate([2*metriccano_unit,5-motor_pillar_spacing/2,motor_base_thick]) cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
            }
            hull() {
                // Screw pillars
                translate([metriccano_unit,motor_pillar_spacing/2,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                translate([2*metriccano_unit,motor_pillar_spacing/2,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
                // Reinforcement
                translate([2*metriccano_unit,motor_pillar_spacing/2-5,motor_base_thick])
                    cylinder(h=axis_motor_pillar_height,r=metriccano_plate_height);
            }
            // Version info
            translate([-2.5*metriccano_unit,0,motor_base_thick/2]) rotate([90,0,-90]) version_text();
            // Frame attachment points
            translate([2*metriccano_unit,metriccano_unit*2,0])
                motor_mount_side_attachment();
            translate([2*metriccano_unit,metriccano_unit*-2,0])
                motor_mount_side_attachment();
            // Bracing between pillars
            translate([metriccano_unit*2.25,0,axis_motor_pillar_height/2+motor_base_thick])
                difference() {
                    // Body of limit switch block
                    cube([metriccano_unit/2,motor_pillar_spacing,axis_motor_pillar_height],center=true);
                    // Gaps for NEMA mount screws & washers
                    translate([0,nema17_screw_sep/2,-axis_motor_pillar_height/2]) rotate([0,90,0]) rotate([0,0,45])
                        cube([6,6,metriccano_unit],center=true);
                    translate([0,-nema17_screw_sep/2,-axis_motor_pillar_height/2]) rotate([0,90,0]) rotate([0,0,45])
                        cube([6,6,metriccano_unit],center=true);
                    // Arbitrary gap for flexures to descend into
                    translate([0,0,axis_motor_pillar_height/2]) 
                        cube([metriccano_unit*2,metriccano_unit*3,26],center=true);
                }
        }
        // Screw holes for 50mm screws in pillars
        pillar_screw_holes(true);
        // Screw holes for frame attachment
        translate([metriccano_unit*2.25-metriccano_screw_head_height,metriccano_unit*2,mb_height-metriccano_unit/2])
            motor_mount_side_holes();
        translate([metriccano_unit*2.25-metriccano_screw_head_height,-metriccano_unit*2,mb_height-metriccano_unit/2])
            motor_mount_side_holes();
    }
}

// A vertical flexure join scalloped in case anyone tries printing it on the surface of the print bed
// Wedge used for each side
module vertical_flexure_wedge(t) hull() {
    translate([0,(t+vertical_flexure_width)/2,0]) cube([vertical_flexure_length/2,vertical_flexure_width,vertical_flexure_height*3],center=true);
    translate([0,t+vertical_flexure_width,0]) cube([vertical_flexure_length,vertical_flexure_width,vertical_flexure_height*3],center=true);
    }

module vertical_flexure(thick=vertical_flexure_thick) difference() {
    translate([0,0,vertical_flexure_height/2]) cube([vertical_flexure_length+1,vertical_flexure_width,vertical_flexure_height],center=true);
    // Scalop the sides of the flexure. Use a blunt wedge
    vertical_flexure_wedge(thick);
    scale([1,-1,1]) vertical_flexure_wedge(thick);
    // Undercut the flexure so it does not touch print bed
    translate([0,0,0.1]) cube([vertical_flexure_length/2,flexure_width*3,layer_height],center=true);
}

// A block that anchors the moving parts to the Z axis
module axis_anchor_block() {
    translate([-flexure_length/2-axis_anchor_block_width,-axis_anchor_block_length/2,0])
        cube([axis_anchor_block_width,axis_anchor_block_length,axis_anchor_block_height]);
}

// These are used for all the lifting linkages in the tool end Z axis lifting section
module axis_lifter_linkage() {
    translate([0,0,axis_lifter_height/2])
        cube([axis_lifter_length,axis_lifter_width,axis_lifter_height],center=true);
}

// The lifter linkage with an unsupported flexure
module axis_unsupported_hinged_lifter_arm() {
    flexure_tab_unsupported();
    translate([(axis_lifter_length+flexure_length)/2,0,0]) axis_lifter_linkage();
    translate([axis_lifter_length+flexure_length,0,0]) flexure_tab_unsupported();
}

// The lifter linkage with the flexure raised so it won't touch the print bed.
module axis_hinged_lifter_arm() {
    flexure_tab();
    translate([(axis_lifter_length+flexure_length)/2,0,0]) axis_lifter_linkage();
    translate([axis_lifter_length+flexure_length,0,0]) flexure_tab();
}

// Block with mounting holes that is lifted on Z axis
module axis_platform() {
        difference() {
            translate([axis_platform_thick/2,0,axis_platform_height/2])
                cube([axis_platform_thick,platform_surface_width,axis_platform_height],center=true);
            // Mounting holes, 10mm spacing
            for (j=[1:platform_surface_width/10])
                for(i=[0:axis_platform_height/10-1])
                    translate([0,-platform_surface_width/2+j*10-5,i*10+5]) rotate([0,90,0]) rotate([0,0,180/8]) cylinder(h=axis_platform_thick*3,r=1.6,center=true,$fn=8);
        }
}

// Triangular brace mounting plate for Z axis frame
axis_bracing_height=30;
axis_bracing_top_width=wall*2;
axis_bracing_top_height=6;
module axis_bracing() translate([-flexure_length/2,0,0]) {
//    translate([-axis_drive_pivot_x/2,0,axis_bracing_height/2])
//        cube([axis_drive_pivot_x,wall*2,axis_bracing_height],center=true);
    // Thin side wall
    translate([-axis_drive_pivot_x/2,0,axis_bracing_height/2])
        cube([axis_drive_pivot_x,wall,axis_bracing_height],center=true);
    // Ridge along top
    // Ridge along top, carefully miss nut holes
    translate([-axis_drive_nut_x/2,0,axis_bracing_height-axis_bracing_top_height/2])
        cube([axis_drive_nut_x-m3_nut_max_width-flexure_length,axis_bracing_top_width,axis_bracing_top_height],center=true);
    /// Tapered bottom to the ridge to print without overhang
    hull() {
        // Minimal lower ridge
        translate([-axis_drive_pivot_x/2,0,axis_bracing_height-axis_bracing_top_height])
            cube([axis_drive_pivot_x,axis_bracing_top_width,0.01],center=true);
        // Minimal top of thin wall
        translate([-axis_drive_pivot_x/2,0,axis_bracing_height-axis_bracing_top_height-wall])
            cube([axis_drive_pivot_x,wall,0.01],center=true);
    }
    // Bottom of wall has to engage Metriccano strip
    translate([-axis_drive_pivot_x/2,0,metriccano_plate_height/2])
        cube([axis_drive_pivot_x,axis_bracing_top_height+1,metriccano_plate_height],center=true);
}

// Z axis drive nut holder
module axis_drive_nut_holder() {
    nut_holder_height=9;
    difference() {
        union() {
            // Cylindrical body with a rectangular area to attach a flexure to
            hull() {
                cylinder(h=nut_holder_height,r=axis_nut_holder_rad);
                translate([axis_nut_holder_rad,0,wall/2]) cube([wall,flexure_width,wall],center=true);
            }
            // The lower lugs for tensioning spring attachment
            difference() {
                union() {
                    // Horizontal octagonal lugs for easy printing.
                    translate([0,0,nut_holder_height-2.31]) rotate([90,0,0]) rotate([0,0,180/8])
                        cylinder(h=drive_lug_length,r=2.5,center=true);
                    // Security lines to hold lug during assembly
                    translate([0,0,layer_height]) difference() {
                        cube([1,axis_anchor_block_length,layer_height*2],center=true);
                        cube([2,drive_lug_length,layer_height*4],center=true);
                    }
                    // Props for lugs
                    translate([0,wall/2-drive_lug_length/2,nut_holder_height/2]) cube([wall*2,wall,nut_holder_height],center=true);
                    translate([0,wall/-2+drive_lug_length/2,nut_holder_height/2]) cube([wall*2,wall,nut_holder_height],center=true);
                }
            }
        }
        // Generously sized hole for drive screw
        cylinder(h=999,r=m3_screw_rad+0.5,center=true,$fn=32);
        // Tapered cavity to hold drive nut.
        translate([0,0,1]) cylinder(h=nut_holder_height+0.001,r1=m3_nut_max_width/2-0.55,r2=m3_nut_max_width/2,$fn=6);
    }
}

// Components for an adjustable limit switch support
module switch_support_bits() difference() {
    union() {
        // Short clamp for Limit Switch wires
        translate([metriccano_unit,-metriccano_unit-1,0]) difference() {
            metriccano_strip(3);
            translate([0,0,metriccano_nut_height]){
                rotate([180,0,0]) metriccano_nut_cavity_tapered(captive=true);
                translate([metriccano_unit*2,0,0])
                    rotate([180,0,0]) metriccano_nut_cavity_tapered(captive=true);
            }
        }
        // U-Shaped part
        metriccano_strip(5);
        translate([0,metriccano_unit,0]) rotate([0,0,90])
            metriccano_slot_strip(2.5,extend_end=metriccano_unit);
        translate([metriccano_unit*4,metriccano_unit,0]) rotate([0,0,90])
            metriccano_slot_strip(2.5,extend_end=metriccano_unit);
    }
    // Grooves for wires
    translate([metriccano_unit,0,metriccano_plate_height]) {
        translate([metriccano_unit-3,0,0])
            rotate([90,0,0]) cylinder(h=metriccano_unit*10,r=0.5,$fn=12,center=true);
        translate([metriccano_unit+3,0,0])
            rotate([90,0,0]) cylinder(h=metriccano_unit*10,r=0.5,$fn=12,center=true);
    }
}

// Lower nut bearing. No anti-backlash band loops.
lower_nut_bar_arm_height=20;
module lower_nut_bar() {
    // Bar with central nut hole
    difference() {
        union() {
            metriccano_strip(5);
            // Support arms
            translate([0,0,0]) cylinder(h=lower_nut_bar_arm_height,r=nut_bar_width/2);
            translate([nut_bar_length,0,0]) cylinder(h=lower_nut_bar_arm_height,r=nut_bar_width/2);
        }
        // Anchor screw holes
        metriccano_screw_hole(lower_nut_bar_arm_height*4);
        translate([nut_bar_length,0,0])
            metriccano_screw_hole(lower_nut_bar_arm_height*4);
        // Anchor nut holes
        metriccano_nut_cavity_tapered(,captive=true,inverted=true);
        translate([nut_bar_length,0,0])
            metriccano_nut_cavity_tapered(,captive=true,inverted=true);
         // Captive nut
        translate([metriccano_unit*2,0,metriccano_plate_height-metriccano_nut_height])
            metriccano_nut_cavity_tapered(captive=true);
    }
}

// Bracket to join Parallelogram Axis Driver free end to XY Table flexure
module axis_driver_link_bracket() {
    translate([metriccano_unit/2,0,0]) metriccano_slot_flatend(4);
translate([-metriccano_unit/2,-metriccano_unit/2,0]) cube([metriccano_unit/2,metriccano_unit,metriccano_unit/2]);
translate([0,0,metriccano_unit]) rotate([0,-90,0]) metriccano_slot_flatend(2,extend_end=metriccano_unit/2);
}

//frame_trio();

// Set to true to print the whole sheet
if (true) {
    translate([210,20,0]) upper_nut_bar();
    translate([190,20,0]) tension_band_booster();
    translate([70,10,0]) lower_nut_bar();
    translate([30,-5,0]) axis_driver_link_bracket();
    translate([70,33,0]) switch_support_bits();
    translate([25,105,0]) frame_trio();
    translate([30,40,0]) nema17_plate();
    translate([145,20,0]) rotate([0,0,180]) nema17_plate();
    translate([170,85,0]) axis_motor_pillar_assy();
}
