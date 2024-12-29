// metriccano_flexures.scad - A selection of Metriccano parts joined by flexures
// Needs flexure definitions and Metriccano library
// (C)2024 vik@diamondage.co.nz GPL 3.0 or later applies.

// Metriccano flexure block, flat strip on one side, block on the other
// Note: Spacing between block and strip is half strip width as these are used in pairs
module metriccano_flexure_block_flat(h) {
    holes=floor(h);
    translate([0,metriccano_strip_width*0.75,0]) metriccano_strip(holes);
    translate([0,metriccano_strip_width*-0.75,0]) metriccano_square_strip(holes);
    translate([flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    translate([metriccano_unit*(holes-1)-flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    // For longert strips, add a central flexure
    if (holes>4)
        translate([metriccano_unit*(holes-1)/2,0,0]) rotate([0,0,90]) flexure_tab();
}


// Metriccano flexure block, flat strip on one side, block on the other, 1 unit castle at each end of the block
// Note: Spacing between block and strip is half strip width as these are used in pairs
module metriccano_flexure_block_u(h) {
    holes=floor(h);
    translate([0,metriccano_strip_width*0.75,0]) metriccano_strip(holes);
    // Flip the main body  over or the castles vover the nut slots
   translate([0,metriccano_strip_width*-0.75,metriccano_unit]) rotate([180,0,0]) metriccano_square_strip(holes);
    translate([0,-metriccano_unit*0.75,metriccano_unit])
        metriccano_square_strip(1);
    translate([metriccano_unit*(holes-1),-metriccano_unit*0.75,metriccano_unit])
        metriccano_square_strip(1);
    translate([flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    translate([metriccano_unit*(holes-1)-flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    // For longert strips, add a central flexure
    if (holes>4)
        translate([metriccano_unit*(holes-1)/2,0,0]) rotate([0,0,90]) flexure_tab();
}
// Metriccano flexure block, flat strip on one side, block on the other, 1 unit castle at each end of the block
// Note: Spacing between block and strip is half strip width as these are used in pairs
module metriccano_flexure_block_bidirectional(h) {
    holes=floor(h);
    translate([0,metriccano_strip_width*0.75,0]) metriccano_strip(holes);
    // Flip the main body  over or the castles vover the nut slots
   translate([0,metriccano_strip_width*-0.75,metriccano_unit]) rotate([180,0,0]) metriccano_square_strip(holes);
    // Vertical pillars
    translate([-metriccano_unit*2,metriccano_unit*-0.75,metriccano_unit*1.5])
        rotate([0,90,0]) metriccano_square_strip(2);
    translate([metriccano_unit*holes,-metriccano_unit*0.75,metriccano_unit*1.5])
        rotate([0,90,0]) metriccano_square_strip(2);
    // Paired flexures
    translate([flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    translate([metriccano_unit*(holes-1)-flexure_length/2,0,0]) rotate([0,0,90]) flexure_tab();
    // For longert strips, add a central flexure
    if (holes>4)
        translate([metriccano_unit*(holes-1)/2,0,0]) rotate([0,0,90]) flexure_tab();
    // Single flexures
   translate([-metriccano_unit*0.75,-metriccano_unit*0.75,0]) flexure_tab();
   translate([metriccano_unit*(holes-0.25),-metriccano_unit*0.75,0]) flexure_tab();
}

// Two 2x2 Metriccano plates joined by horizontal and vertical flexures.
// Minimum length 50mm
module joined_mettricano_2_via_flexures(fl,onetall=false) {
    if (onetall)
        scale([1,1,2]) metriccano_plate(2,2);
    else
        metriccano_plate(2,2);
    translate([fl+metriccano_hole_spacing,0,0]) metriccano_plate(2,2);
    // Very thin flexure joining them. Slightly short so as not to rub overhanging parts
    translate([metriccano_unit,metriccano_unit/2-0.4,0]) cube([fl,0.8,metriccano_plate_height-layer_height]);
    // Stress relief
    translate([metriccano_unit*1.5,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
    translate([fl+metriccano_unit/2,metriccano_unit/2,metriccano_plate_height/2])
        rotate([0,0,45]) cube([2,2,metriccano_plate_height],center=true);
}
