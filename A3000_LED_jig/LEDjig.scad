/* Jig to grind down 5x10mm LEDs
 * to 2x10mm
 */

difference(){
  cube([50,30,10]);
  {
    translate([10,0,6.5])
      cube([10.1,30,3.5]);
    translate([30,0,8])
      cube([10.1,30,2]);
  }
}