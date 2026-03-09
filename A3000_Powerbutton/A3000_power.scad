$fn = 100;  // Global facet count

// Parameters
rod_length         = 176;      // Rod length (mm)
rod_size           = 5.5;      // Rod cross-section (mm)

plate_width        = 25.7;     // Plate overall width (mm)
plate_length       = 12.8;     // Plate overall length (mm)
plate_thickness    = 2;        // Plate thickness (mm)
plate_round_radius = 0.75;     // Plate corner radius (mm)

button_bottom_width = 22.7;    // Button bottom x-dimension (mm)
button_top_width    = 22;      // Button top x-dimension (mm)
button_bottom_len   = 8.8;     // Button bottom y-dimension (mm)
button_top_len      = 8.4;     // Button top y-dimension (mm)
button_height       = 11;      // Button height (mm)
button_round_radius = 0.75;    // Button edge rounding radius (mm)

// --- Rod ---
// The rod is centered in x, and shifted in y by -1 so it lies directly under the button.
module rod() {
    translate([-rod_size/2, -rod_size/2 - 1, 0])
        cube([rod_size, rod_size, rod_length], center = false);
}

// --- Plate ---
// Create a 2D rounded rectangle (plate) and extrude it.
module rounded_plate() {
    linear_extrude(height = plate_thickness)
         offset(r = plate_round_radius)
            square([plate_width - 2*plate_round_radius, plate_length - 2*plate_round_radius], center = true);
}
module plate() {
    translate([0, 0, rod_length])
        rounded_plate();
}

// --- 2D Rounded Rectangle Module ---
// Generates a 2D rounded rectangle of overall width w and length l with corner radius r.
module rounded_rect_2d(w, l, r) {
    offset(r = r)
         square([w - 2*r, l - 2*r], center = true);
}

// --- Rounded Tapered Button using Hull ---
// Build two 2D rounded rectangles (for the bottom and top profiles),
// give them a very small extrusion (0.01 mm), then hull them to form a solid.
module rounded_power_button() {
    // z-levels for the bottom and top of the button:
    z0 = rod_length + plate_thickness;  // bottom z
    z1 = z0 + button_height;              // top z
    
    // Translate so that the button's 2D profiles are shifted by (0, -1, 0).
    translate([0, -1, 0]) {
        hull() {
            // Bottom profile at z0 (with a small extrusion)
            translate([0, 0, z0])
                linear_extrude(height = 0.01)
                    rounded_rect_2d(button_bottom_width, button_bottom_len, button_round_radius);
            // Top profile at z1 (with a small extrusion)
            translate([0, 0, z1])
                linear_extrude(height = 0.01)
                    rounded_rect_2d(button_top_width, button_top_len, button_round_radius);
        }
    }
}

// --- Cutouts ---
// Subtract two rectangular voids from the bottom (underside) of the button to save material,
// while ensuring that the remaining wall thickness is 1.5 mm.
module cutouts() {
    // In z, we want the cutout to extend from the button's bottom up to:
    // button_height - 1.5 mm (i.e. leave 1.5 mm material at the top of the button's bottom portion).
    // Hence the cutout height:
    cube_h = button_height - 1.5;  // 11 - 1.5 = 9.5 mm

    // For the button's bottom 2D profile (a rounded rectangle) we approximate its extents:
    // Its full width is button_bottom_width = 22.7 mm.
    // To leave a 1.5 mm thick wall at the left and right edges, total removable width = 22.7 - 3.0 = 19.7 mm.
    // Dividing equally between two cutouts:
    cube_w = 18 / 2;  // ≈ 9.85 mm.
    
    // For the y dimension, the button bottom length is button_bottom_len = 8.8 mm.
    // To leave a 1.5 mm margin on the side where the plate is more visible, we take:
    cube_l = 8.8 - 1.5;  // = 7.3 mm.
    
    // In the button's 2D profile (before translation), the x extents are from -button_bottom_width/2 to +button_bottom_width/2.
    // That is, from -11.35 to +11.35. We want the left cutout to begin 1.5 mm from the left edge:
    // Left cutout x start = -11.35 + 1.5 = -9.85.
    // And if its width is 9.85, it will span from x = -9.85 to x = 0.
    // The right cutout will span from x = 0 to x = +9.85.
    // For y: the button's bottom face (before translation) has y extents from -button_bottom_len/2 to +button_bottom_len/2,
    // i.e. from -4.4 to +4.4. We want the cutouts on the side where the plate is more visible.
    // Because the button is translated by (0, -1, 0), its effective 2D profile is shifted in y by -1.
    // For this example, we’ll place the cutouts so that their top edges align with y = button_bottom_len/2 (i.e. 4.4 before translation).
    // Thus the cutouts in y extend from 4.4 - cube_l to 4.4.
    // That is, from 4.4 - 7.3 = -2.9 to 4.4.
    
    // Finally, in z the cutouts extend from z0 to z0 + cube_h.
    z0 = rod_length + plate_thickness; // button bottom z level
    
    // Left cube:
    translate([-9.75, -2.9, z0])
        cube([cube_w, cube_l, cube_h], center = false);
    // Right cube:
    translate([0.4, -2.9, z0])
        cube([cube_w, cube_l, cube_h], center = false);
}

// --- Final Button ---
// Subtract the cutouts from the rounded button.
module final_button() {
    difference() {
        rounded_power_button();
        cutouts();
    }
}

// ---------- Assemble the Parts ----------
color("#CCC0AE") {
rod();
plate();
final_button();
}



// ---------- Add Text on Top of the Button ----------
// Place the text "I/O" in red on the top surface of the button.
// The top of the button is at z = rod_length + plate_thickness + button_height.
// Because the button is translated by (0, -1, 0), we use the same offset in y.
color("#666666")
translate([0, -1, rod_length + plate_thickness + button_height + 0.2])  // slight offset above the top
    rotate([0,0,180])
    linear_extrude(height = 0.1)  // text thickness
        text(" I / O", font = "Arial:style=Bold", size = 5, halign = "center", valign = "center");
