// A3000 Power Button Bracket

// Dimensions
base_long = 79; // Long edge of the L
base_short = 51; // Short edge of the L
wall_height = 30; // Height of the vertical wall
wall_width = 44; // Width of the vertical wall
hole_diameter = 3.6; // Diameter of circular holes (approximate)
square_hole_size = 6.5; // Size of square cutout
tab_width = 15; // Width of the bent tab
tab_height = 8; // Height of the bent tab (approximate)
tab_offset = 20; // Offset from one edge

vertical_wall_offset = 3; // Original metal piece has one piece floating
			  // but if you print this on an FDM printer, set
			  // it to zero.

module base_plate() {
    difference() {
        union() {
            cube([base_short, 1, 18]); // Base plate
            cube([10,1,base_long]);
        }
        // Square cutout
        translate([17.5, -0.1, 6.5]) 
            cube([square_hole_size, 1.2, square_hole_size]);


        // Circular holes
        
        translate([4.5+hole_diameter/2, 1.1, 68+hole_diameter/2]) 
          rotate([90, 0, 0]) 
            cylinder(h=2, d=hole_diameter, $fn=50);
        
        translate([43+hole_diameter/2, 1.1, 4.5+hole_diameter/2]) 
          rotate([90, 0, 0]) 
            cylinder(h=2, d=hole_diameter, $fn=50);
        
    }
}

module vertical_wall() {
            cube([1, wall_height, wall_width]); // Vertical wall
            translate([0, vertical_wall_offset, wall_width])
            cube([10, wall_height-vertical_wall_offset, 1]);
}


module bracket() {
    union() {
        base_plate();
        vertical_wall();
       // tab();
    }
}

color ("#cccccc")
bracket();
