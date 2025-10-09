/*




***CHANGELOG***
07-05-2024     -     Removed "ALERT" popup for WCS offset and replaced with warning message in GCODE comments when offset set to zero
                     Removed all "ALERT" popups and added warnings to resultant GCODE as Fusion no longer supports popup warning messages


                     

*/




description = "CNC3D - Nighthawk - GRBL - Plasma Only";
vendor = "CNC3D PTY LTD";
vendorUrl = "http://www.cnc3d.com.au";
model = "Plasma Cutter";
obversion = '1.01';										// date updated 07-05-2024
longDescription = description + " : Post" + obversion; 	// adds description to post library dialog box
legal = "CNC3D PTY LTD Australia";
certificationLevel = 2;

extension = "nc";                                                                                                         // file extension of/ode file
//setEOL(CRLF);                                                                                                           // end-of-line type : use CRLF for windows

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,=_-*/\\:";
capabilities = CAPABILITY_JET;                                                                                            // intended for waterjet/plasma/laser
tolerance = spatial(0.01, MM);
minimumChordLength = spatial(0.25, MM);
minimumCircularRadius = spatial(0.125, MM);
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.1);                                                                                        // was 0.01
maximumCircularSweep = toRad(350);
allowHelicalMoves = true;
allowedCircularPlanes = (1 << PLANE_XY);// | (1 << PLANE_ZX) | (1 << PLANE_YZ); // only XY, ZX, and YZ planes

// the above circular plane limitation appears to be a solution to the faulty arcs problem (but is not entirely)
// an alternative is to set EITHER minimumChordLength OR minimumCircularRadius to a much larger value, like 0.5mm

// user-defined properties : defaults are set, but they can be changed from a dialog box in Fusion when doing a post.
properties =
{
   spindleOnOffDelay: 1.0,                  // time (in seconds) the spindle needs to get up to speed or stop, or laser/plasma pierce delay
   machineHomeZ : -5,                      // absolute machine coordinates where the machine will move to at the end of the job - first retracting Z, then moving home X Y
   machineHomeX : 0,                      // always in millimeters
   machineHomeY : 0,
   gotoMCSatend : false,                    // true will do G53 G0 x{machinehomeX} y{machinehomeY}, false will do G0 x{machinehomeX} y{machinehomeY} at end of program
   UseZ : false,                            // if true then Z will be moved to 0 at beginning and back to 'retract height' at end

   //plasma stuff
   plasma_usetouchoff : false, // use probe for touchoff if true
   plasma_touchoffOffset : 5.0, // offset from trigger point to real Z0, used in G10 line

   linearizeSmallArcs: true,                // arcs with radius < toolRadius have radius errors, linearize instead?
   machineVendor : "CNC3D",
   modelMachine : "Plasma",
   machineControl : "NighthawkCNC",


};

// user-defined property definitions - note, do not skip any group numbers
groupDefinitions = {
    spindle: {title: "Torch", description: "Torch options", order: 1},
    safety: {title: "Safety", description: "Safety options", order: 2},
    toolChange: {title: "Tool Changes", description: "Tool change options", order: 3},
    startEndPos: {title: "Job Start Z and Job End X,Y,Z Coordinates", description: "Set the spindle start and end position", order: 4},
    arcs: {title: "Arcs", description: "Arc options", order: 5},
    laserPlasma: {title: "Laser / Plasma", description: "Laser / Plasma options", order: 6},
    machine: {title: "Machine", description: "Machine options", order: 7}
};
propertyDefinitions = {

    spindleOnOffDelay:  {
      group: "Torch Settings",
      title: "TORCH pierce delay",
      description: "Time (in seconds) the torch needs to pierce the material",
      type: "number",
    },


   gotoMCSatend: {
      group: "startEndPos",
      title:"EndPos: Use Machine Coordinates (G53) at end of job?",
      description: "Yes will do G53 G0 x{machinehomeX} y(machinehomeY) (Machine Coordinates), No will do G0 x(machinehomeX) y(machinehomeY) (Work Coordinates) at end of program",
      type:"boolean",
   },
   machineHomeX: {
      group: "startEndPos",
      title:"End X: End of job X position (MM).",
      description: "(G53 or G54) X position to move to in Millimeters",
      type:"spatial",
   },
   machineHomeY: {
      group: "startEndPos",
      title:"End Y: End of job Y position (MM).",
      description: "(G53 or G54) Y position to move to in Millimeters.",
      type:"spatial",
   },
   machineHomeZ: {
      group: "startEndPos",
      title:"Start/End Z: START and End of job Z position (MCS Only) (MM)",
      description: "G53 Z position to move to in Millimeters, normally negative.  Moves to this distance below Z home.",
      type:"spatial",
   },

   linearizeSmallArcs: {
      group: "arcs",
      title:"ARCS: Linearize Small Arcs",
      description: "Arcs with radius < toolRadius can have mismatched radii, set this to Yes to linearize them. This solves G2/G3 radius mismatch errors.",
      type:"boolean",
   },

   UseZ:          {title:"PLASMA: Use Z motions at start and end.", description:"Tick Box if you have a PLASMA on a gantry with Z motion.", group:"laserPlasma", type:"boolean"},
   plasma_usetouchoff:  {title:"PLASMA: Use Z touchoff probe routine", description:"Set to true if have a touchoff probe for Plasma.", group:"laserPlasma", type:"boolean"},
   plasma_touchoffOffset:{title:"PLASMA: Plasma touch probe offset", description:"Offset in Z at which the probe triggers, always Millimeters, always positive.", group:"laserPlasma", type:"spatial"},

   machineVendor: {
      group: "machine",
      title:"Machine Vendor",
      description: "Machine vendor defined here will be displayed in header if machine config not set.",
      type:"string",
   },
   modelMachine: {
      group: "machine",
      title:"Machine Model",
      description: "Machine model defined here will be displayed in header if machine config not set.",
      type:"string",
   },
   machineControl: {
      group: "machine",
      title:"Machine Control",
      description: "Machine control defined here will be displayed in header if machine config not set.",
      type:"string",
    }
};

// USER ADJUSTMENTS FOR PLASMA
plasma_probedistance = 30;   // distance to probe down in Z, always in millimeters
plasma_proberate = 100;      // feedrate for probing, in mm/minute
// END OF USER ADJUSTMENTS

var debug = false;
// creation of all kinds of G-code formats - controls the amount of decimals used in the generated G-Code
var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var abcFormat = createFormat({decimals:3, forceDecimal:true, scale:DEG});
var arcFormat = createFormat({decimals:(unit == MM ? 3 : 4)});
var feedFormat = createFormat({decimals:0});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:1, forceDecimal:true}); // seconds
//var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X", force:false}, xyzFormat);
var yOutput = createVariable({prefix:"Y", force:false}, xyzFormat);
var zOutput = createVariable({prefix:"Z", force:false}, xyzFormat); // dont need Z every time
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:false}, rpmFormat);
var mOutput = createVariable({force:false}, mFormat); // only use for M3/4/5

// for arcs
var iOutput = createReferenceVariable({prefix:"I", force:true}, arcFormat);
var jOutput = createReferenceVariable({prefix:"J", force:true}, arcFormat);
var kOutput = createReferenceVariable({prefix:"K", force:true}, arcFormat);

var gMotionModal = createModal({}, gFormat);                                  // modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat);                                  // modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat);                                // modal group 5 // G93-94
var gUnitModal = createModal({}, gFormat);                                    // modal group 6 // G20-21
var gWCSOutput = createModal({}, gFormat);                                    // for G54 G55 etc

var sequenceNumber = 1;        //used for multiple file naming
var multipleToolError = false; //used for alerting during single file generation with multiple tools
var filesToGenerate = 1;       //used to figure out how many files will be generated so we can diplay in header
var minimumFeedRate = toPreciseUnit(45,MM); // GRBL lower limit in mm/minute
var fileIndexFormat = createFormat({width:2, zeropad: true, decimals:0});
var isNewfile = false;  // set true when a new file has just been started

var isLaser = false;    // set true for laser/water/
var isPlasma = true;   // set true for plasma
var cutPower = 0;          // the setpower value, for S word when laser cutting
var cutmode = 0;        // M3 or M4
var Zmax = 0;
var workOffset = 0;
var haveRapid = false;  // assume no rapid moves
var powerOn = false;    // is the laser power on? used for laser when haveRapid=false
var retractHeight = 1;  // will be set by onParameter and used in onLinear to detect rapids
var clearanceHeight = 10;  // will be set by onParameter
var topHeight = 1;      // set by onParameter
var leadinRate = 314;   // set by onParameter: the lead-in feedrate,plasma
var linmove = 1;        // linear move mode
var toolRadius;         // for arc linearization
var plasma_pierceHeight = 1; // set by onParameter from Linking|PierceClearance
var coolantIsOn = 0;    // set when coolant is used to we can do intelligent turn off
var currentworkOffset = 54; // the current WCS in use, so we can retract Z between sections if needed


function toTitleCase(str)
   {
   // function to reformat a string to 'title case'
   return str.replace( /\w\S*/g, function(txt)
      {
      return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
      });
   }


function checkMinFeedrate(section, op)
   {
   var alertMsg = "";
   if (section.getParameter("operation:tool_feedCutting") < minimumFeedRate)
      {
      var alertMsg = "Cutting\n";
      //alert("Warning", "The cutting feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (section.getParameter("operation:tool_feedRetract") < minimumFeedRate)
      {
      var alertMsg = alertMsg + "Retract\n";
      //alert("Warning", "The retract feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (section.getParameter("operation:tool_feedEntry") < minimumFeedRate)
      {
      var alertMsg = alertMsg + "Entry\n";
      //alert("Warning", "The retract feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (section.getParameter("operation:tool_feedExit") < minimumFeedRate)
      {
      var alertMsg = alertMsg + "Exit\n";
      //alert("Warning", "The retract feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (section.getParameter("operation:tool_feedRamp") < minimumFeedRate)
      {
      var alertMsg = alertMsg + "Ramp\n";
      //alert("Warning", "The retract feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (section.getParameter("operation:tool_feedPlunge") < minimumFeedRate)
      {
      var alertMsg = alertMsg + "Plunge\n";
      //alert("Warning", "The retract feedrate in " + op + "  is set below the minimum feedrate that grbl supports.");
      }

   if (alertMsg != "")
      {
      var fF = createFormat({decimals: 0, suffix: (unit == MM ? "mm" : "in" )});
      var fo = createVariable({}, fF);
      var feedWarn = "Warning: The following feedrates in " + op + " are set below the minimum feedrate that GRBL supports. The feedrate should be higher than " + fo.format(minimumFeedRate) + " per minute.\n\n" + alertMsg
      warning(feedWarn);
      writeComment(feedWarn);
      
   }
   }

function writeBlock()
   {
   writeWords(arguments);
   }

function onPassThrough(text)
   {
   var commands = String(text).split(",");
   for (text in commands)
      {
      writeBlock(commands[text]);
      }
   }

function myMachineConfig()
   {
   // 3. here you can set all the properties of your machine if you havent set up a machine config in CAM.  These are optional and only used to print in the header.
   myMachine = getMachineConfiguration();
   if (!myMachine.getVendor())
      {
      // machine config not found so we'll use the info below
      myMachine.setWidth(1200);
      myMachine.setDepth(1200);
      myMachine.setHeight(60);
      myMachine.setMaximumSpindlePower(1000);
      myMachine.setMaximumSpindleSpeed(1000);
      myMachine.setMilling(false);
      myMachine.setTurning(false);
       myMachine.setToolChanger(false);
      myMachine.setNumberOfTools(1);
      myMachine.setNumberOfWorkOffsets(6);
      myMachine.setVendor(properties.machineVendor);
      myMachine.setModel(properties.modelMachine);
      myMachine.setControl(properties.machineControl);
      }
   }

function formatComment(text)
   {
   return ("(" + filterText(String(text), permittedCommentChars) + ")");
   }

function writeComment(text)
   {
   // Remove special characters which could confuse GRBL : $, !, ~, ?, (, )
   // In order to make it simple, I replace everything which is not A-Z, 0-9, space, : , .
   // Finally put everything between () as this is the way GRBL & UGCS expect comments
   // v20 - split the line so no comment is longer than 70 chars
   if (text.length > 70)
      {
      //text = String(text).replace( /[^a-zA-Z\d:=,.]+/g, " "); // remove illegal chars
      text = formatComment(text);
      var bits = text.split(" "); // get all the words
      var out = '';
      for (i = 0; i < bits.length; i++)
         {
         out += bits[i] + " ";
         if (out.length > 60)           // a long word on the end can take us to 80 chars!
            {
            writeln("(" + out.trim() + ")");
            out = "";
            }
         }
      if (out.length > 0)
         writeln("(" + out.trim() + ")");
      }
   else
      writeln(formatComment(text));
   }

function writeHeader(secID)
   {
   //writeComment("Header start " + secID);
   if (multipleToolError)
      {
      writeComment("Warning: Multiple tools found.  This post does not support tool changes.  You should repost and select True for Multiple Files in the post properties.");
      writeln("");
      }

   var productName = getProduct();
   writeComment("Made in : " + productName);
   writeComment("G-Code optimized for " + myMachine.getControl() + " controller");
   writeComment(description);
   cpsname = FileSystem.getFilename(getConfigurationPath());
   writeComment("Post-Processor : " + cpsname + " v" + obversion );
   //writeComment("Post processor documentation: " + properties.postProcessorDocs );
   var unitstr = (unit == MM) ? 'mm' : 'inch';
   writeComment("Units = " + unitstr );
   if (isJet())
      writeComment("UseZ = " + properties.UseZ);

   writeln("");
   if (hasGlobalParameter("document-path"))
      {
      var path = getGlobalParameter("document-path");
      if (path)
         {
         writeComment("Drawing name : " + path);
         }
      }

   if (programName)
      {
      writeComment("Program Name : " + programName);
      }
   if (programComment)
      {
      writeComment("Program Comments : " + programComment);
      }
   writeln("");

   if (properties.generateMultiple && filesToGenerate > 1)
      {
      writeComment(numberOfSections + " Operation" + ((numberOfSections == 1) ? "" : "s") + " in " + filesToGenerate + " files.");
      writeComment("File List:");
      //writeComment("  " +  FileSystem.getFilename(getOutputPath()));
      for (var i = 0; i < filesToGenerate; ++i)
         {
         filenamePath = FileSystem.replaceExtension(getOutputPath(), fileIndexFormat.format(i + 1) + "of" + filesToGenerate + "." + extension);
         filename = FileSystem.getFilename(filenamePath);
         writeComment("  " + filename);
         }
      writeln("");
      writeComment("This is file: " + sequenceNumber + " of " + filesToGenerate);
      writeln("");
      writeComment("This file contains the following operations: ");
      }
   else
      {
      writeComment(numberOfSections + " Operation" + ((numberOfSections == 1) ? "" : "s") + " :");
      }

   for (var i = secID; i < numberOfSections; ++i)
      {
      var section = getSection(i);
      var tool = section.getTool();
      var rpm = section.getMaximumSpindleSpeed();
      isLaser = isPlasma = false;
      switch (tool.type)
         {
         case TOOL_LASER_CUTTER:
            isLaser = true;
            break;
         case TOOL_WATER_JET:
         case TOOL_PLASMA_CUTTER:
            isPlasma = true;
            break;
         default:
            isLaser = false;
            isPlasma = false;
         }

      if (section.hasParameter("operation-comment"))
         {
         writeComment((i + 1) + " : " + section.getParameter("operation-comment"));
         var op = section.getParameter("operation-comment")
         }
      else
         {
         writeComment(i + 1);
         var op = i + 1;
         }
      if (section.workOffset > 0)
         {
         writeComment("  Work Coordinate System : G" + (section.workOffset + 53));
         }
      if (isLaser || isPlasma)
         writeComment("  Tool #" + tool.number + ": " + toTitleCase(getToolTypeName(tool.type)) + " Diam = " + xyzFormat.format(tool.jetDiameter) + unitstr);
      else
         {
         writeComment("  Tool #" + tool.number + ": " + toTitleCase(getToolTypeName(tool.type)) + " " + tool.numberOfFlutes + " Flutes, Diam = " + xyzFormat.format(tool.diameter) + unitstr + ", Len = " + tool.fluteLength.toFixed(2) + unitstr);
         if (properties.routerType != "other")
            {
            writeComment("  Spindle : RPM = " + round(rpm,0) + ", set router dial to " + rpm2dial(rpm, op));
            }
         else
            {
            writeComment("  Spindle : RPM = " + round(rpm,0));
            }
         }
      checkMinFeedrate(section, op);
      var machineTimeInSeconds = section.getCycleTime();
      var machineTimeHours = Math.floor(machineTimeInSeconds / 3600);
      machineTimeInSeconds = machineTimeInSeconds % 3600;
      var machineTimeMinutes = Math.floor(machineTimeInSeconds / 60);
      var machineTimeSeconds = Math.floor(machineTimeInSeconds % 60);
      var machineTimeText = "  Machining time : ";
      if (machineTimeHours > 0)
         {
         machineTimeText = machineTimeText + machineTimeHours + " hours " + machineTimeMinutes + " min ";
         }
      else if (machineTimeMinutes > 0)
         {
         machineTimeText = machineTimeText + machineTimeMinutes + " min ";
         }
      machineTimeText = machineTimeText + machineTimeSeconds + " sec";
      writeComment(machineTimeText);

      if (properties.generateMultiple && (i + 1 < numberOfSections))
         {
         if (tool.number != getSection(i + 1).getTool().number)
            {
            writeln("");
            writeComment("Remaining operations located in additional files.");
            break;
            }
         }
      }
   if (isLaser || isPlasma)
      {
      allowHelicalMoves = false; // laser/plasma not doing this, ever
      }
   writeln("");

   gAbsIncModal.reset();
   gFeedModeModal.reset();
   gPlaneModal.reset();
   writeBlock(gAbsIncModal.format(90), gFeedModeModal.format(94), gPlaneModal.format(17) );
   switch (unit)
      {
      case IN:
         writeBlock(gUnitModal.format(20));
         break;
      case MM:
         writeBlock(gUnitModal.format(21));
         break;
      }
   //writeComment("Header end");
   writeln("");
   }

function onOpen()
   {
   if (debug) writeComment("onOpen");
   // Number of checks capturing fatal errors
   // 2. is RadiusCompensation not set incorrectly ?
   onRadiusCompensation();

   // 3. moved to top of file
   myMachineConfig();

   // 4.  checking for duplicate tool numbers with the different geometry.
   // check for duplicate tool number
   for (var i = 0; i < getNumberOfSections(); ++i)
      {
      var sectioni = getSection(i);
      var tooli = sectioni.getTool();
      if (i < (getNumberOfSections() - 1) && (tooli.number != getSection(i + 1).getTool().number))
         {
         filesToGenerate++;
         }
      for (var j = i + 1; j < getNumberOfSections(); ++j)
         {
         var sectionj = getSection(j);
         var toolj = sectionj.getTool();
         if (tooli.number == toolj.number)
            {
            if (xyzFormat.areDifferent(tooli.diameter, toolj.diameter) ||
                  xyzFormat.areDifferent(tooli.cornerRadius, toolj.cornerRadius) ||
                  abcFormat.areDifferent(tooli.taperAngle, toolj.taperAngle) ||
                  (tooli.numberOfFlutes != toolj.numberOfFlutes))
               {
               error(
                  subst(
                     localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                     sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                     sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
                  )
               );
               return;
               }
            }
         else
            {
            if (properties.generateMultiple == false)
               {
               multipleToolError = true;
               }
            }
         }
      }
   if (multipleToolError)
      {
      var multiError = "Warning Multiple tools found.  This post does not support tool changes.  You should repost and select True for Multiple Files in the post properties.";
      warning (multiError);
      writeComment(multiError);
      //alert("Warning", "Multiple tools found.  This post does not support tool changes.  You should repost and select True for Multiple Files in the post properties.");
      }

   numberOfSections = getNumberOfSections();
   writeHeader(0);
   gMotionModal.reset();

   if (properties.plasma_usetouchoff)
      properties.UseZ = true; // force it on, we need Z motion, always

   if (properties.UseZ)
      zOutput.format(1);
   else
      zOutput.format(0);
   //writeComment("onOpen end");
   }

function onComment(message)
   {
   writeComment(message);
   }

function forceXYZ()
   {
   xOutput.reset();
   yOutput.reset();
   zOutput.reset();
   }

function forceAny()
   {
   forceXYZ();
   feedOutput.reset();
   gMotionModal.reset();
   }

function forceAll()
   {
   //writeComment("forceAll");
   forceAny();
   sOutput.reset();
   gAbsIncModal.reset();
   gFeedModeModal.reset();
   gMotionModal.reset();
   gPlaneModal.reset();
   gUnitModal.reset();
   gWCSOutput.reset();
   mOutput.reset();
   }

// calculate the power setting for the laser
function calcPower(perc)
   {
   var PWMMin = 0;  // make it easy for users to change this
   var PWMMax = 1000;
   var v = PWMMin + (PWMMax - PWMMin) * perc / 100.0;
   return v;
   }

// go to initial position and optionally output the height check code before torch turns on
function gotoInitial(checkit)
   {
   if (debug) writeComment("gotoInitial start");
   var sectionId = getCurrentSectionId();       // what is the number of this operation (starts from 0)
   var section = getSection(sectionId);         // what is the section-object for this operation
   var maxfeedrate = section.getMaximumFeedrate();



   // Rapid move to initial position, first XY, then Z, and do tool height check if needed

   forceAny();
   var initialPosition = getFramePosition(currentSection.getInitialPosition());
   if (isLaser || isPlasma)
      {
      f = feedOutput.format(maxfeedrate);
      checkit = false; // never do a tool height check for laser/plasma, even if the user turns it on
      }
   else
      f = "";
   writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y), f);
   if (checkit)
      if ( (isNewfile || isFirstSection()) && properties.checkZ && (properties.checkFeed > 0) )
         {
         // do a Peter Stanton style Z seek and stop for a height check
         z = zOutput.format(clearanceHeight);
         f = feedOutput.format(toPreciseUnit(properties.checkFeed,MM));
         writeln("(Tool Height check https://youtu.be/WMsO24IqRKU?t=1059)");
         writeBlock(gMotionModal.format(1), z, f );
         writeBlock(mOutput.format(0));
         }
   if (debug) writeComment("gotoInitial end");
   }

// write a G53 Z retract
function writeZretract()
   {
   zOutput.reset();
   writeln("(This relies on homing, do not use if machine does not have homing enabled )");
   writeBlock(gFormat.format(53), gMotionModal.format(0), zOutput.format(toPreciseUnit( properties.machineHomeZ, MM)));  // Retract spindle to Machine Z Home
   gMotionModal.reset();
   zOutput.reset();
   }


function onSection()
   {
   var nmbrOfSections = getNumberOfSections();  // how many operations are there in total
   var sectionId = getCurrentSectionId();       // what is the number of this operation (starts from 0)
   var section = getSection(sectionId);         // what is the section-object for this operation
   var tool = section.getTool();
   var maxfeedrate = section.getMaximumFeedrate();
   if (debug) writeComment("onSection " + sectionId);
   haveRapid = false; // drilling sections will have rapids even when other ops do not

   onRadiusCompensation(); // must check every section

   if (isPlasma)
      {
      if (topHeight > plasma_pierceHeight)
         error("TOP HEIGHT MUST BE BELOW PLASMA PIERCE HEIGHT");
      if ((topHeight <= 0) && properties.plasma_usetouchoff)
         error("TOPHEIGHT MUST BE GREATER THAN 0");
      writeComment("Plasma pierce height " + plasma_pierceHeight);
      writeComment("Plasma topHeight " + topHeight);
      }

   toolRadius = tool.diameter / 2.0;

   //TODO : plasma check that top height mode is from stock top and the value is positive
   //(onParameter =operation:topHeight mode= from stock top)
   //(onParameter =operation:topHeight value= 0.8)

   if (!isFirstSection() && properties.generateMultiple && (tool.number != getPreviousSection().getTool().number))
      {
      sequenceNumber ++;
      //var fileIndexFormat = createFormat({width:3, zeropad: true, decimals:0});
      var path = FileSystem.replaceExtension(getOutputPath(), fileIndexFormat.format(sequenceNumber) + "of" + filesToGenerate + "." + extension);
      redirectToFile(path);
      forceAll();
      writeHeader(getCurrentSectionId());
      isNewfile = true;  // trigger a spindleondelay
      }
   writeln(""); // put these here so they go in the new file
   //writeComment("Section : " + (sectionId + 1) + " haveRapid " + haveRapid);

   // Insert a small comment section to identify the related G-Code in a large multi-operations file
   var comment = "Operation " + (sectionId + 1) + " of " + nmbrOfSections;
   if (hasParameter("operation-comment"))
      {
      comment = comment + " : " + getParameter("operation-comment");
      }
   writeComment(comment);
   if (debug)
      writeComment("retractHeight = " + retractHeight);
   // Write the WCS, ie. G54 or higher.. default to WCS1 / G54 if no or invalid WCS
   if (!isFirstSection() && (currentworkOffset !=  (53 + section.workOffset)) )
      {
      writeZretract();
      }
   if ((section.workOffset < 1) || (section.workOffset > 6))
      {
      var wcsOffset = "**Warning** Invalid Work Coordinate System. Select WCS 1 to 6 in CAM software. In Fusion360, set the WCS in CAM-workspace -> Setup-properties -> PostProcess-tab. Default WCS1 / G54 selected";
      warning(wcsOffset);
      writeComment(wcsOffset);

           // alert("Warning", "Invalid Work Coordinate System. Select WCS 1..6 in SETUP:PostProcess tab. Selecting default WCS1/G54");
           //section.workOffset = 1;  // If no WCS is set (or out of range), then default to WCS1 / G54 : swarfer: this appears to be readonly

      writeBlock(gWCSOutput.format(54));  // output what we want, G54
      currentworkOffset = 54;
      }
   else
      {
      writeBlock(gWCSOutput.format(53 + section.workOffset));  // use the selected WCS
      currentworkOffset = 53 + section.workOffset;
      }
   writeBlock(gAbsIncModal.format(90));  // Set to absolute coordinates

   cutmode = -1;
   //writeComment("isMilling=" + isMilling() + "  isjet=" +isJet() + "  islaser=" + isLaser);
   switch (tool.type)
      {
      case TOOL_WATER_JET:
         writeComment("Waterjet cutting with GRBL");
         cutPower = calcPower(100); // always 100%
         cutmode = 3;
         isLaser = false;
         isPlasma = true;
         //writeBlock(mOutput.format(cutmode), sOutput.format(power));
         break;
      case TOOL_LASER_CUTTER:
         writeComment("Laser cutting with GRBL");
         isLaser = true;
         isPlasma = false;
         var pwas = cutPower;
         switch (currentSection.jetMode)
            {
            case JET_MODE_THROUGH:
               cutPower = calcPower(properties.PowerThrough);
               writeComment("LASER THROUGH CUTTING " + properties.PowerThrough + "percent = S" + cutPower);
               break;
            case JET_MODE_ETCHING:
               cutPower = calcPower(properties.PowerEtch);
               writeComment("LASER ETCH CUTTING " + properties.PowerEtch + "percent = S" + cutPower);
               break;
            case JET_MODE_VAPORIZE:
               cutPower = calcPower(properties.PowerVaporise);
               writeComment("LASER VAPORIZE CUTTING " + properties.PowerVaporise + "percent = S" + cutPower);
               break;
            default:
               error(localize("Unsupported cutting mode."));
               return;
            }
         // figure cutmode, M3 or M4
         cutmode = 4; // always M4 mode
         if (pwas != cutPower)
            {
            sOutput.reset();
            //if (isFirstSection())
            if (cutmode == 3)
               writeBlock(mOutput.format(cutmode), sOutput.format(0)); // else you get a flash before the first g0 move
            else
               writeBlock(mOutput.format(cutmode), sOutput.format(cutPower));
            }
         break;
      case TOOL_PLASMA_CUTTER:
         writeComment("Plasma cutting with GRBL.");
         if (properties.plasma_usetouchoff)
            writeComment("Using torch height probe and pierce delay.");
         cutPower = calcPower(100); // always 100%
         cutmode = 3;
         isLaser = false;
         isPlasma = true;
         //writeBlock(mOutput.format(cutmode), sOutput.format(power));
         break;
      default:
         //writeComment("tool.type = " + tool.type); // all milling tools
         isPlasma = isLaser = false;
         break;
      }

 
   forceXYZ();

   var remaining = currentSection.workPlane;
   if (!isSameDirection(remaining.forward, new Vector(0, 0, 1)))
      {
      var sameDirec = "**Error** Tool-Rotation detected - This post only supports 3 Axis";
      warning(sameDirec);
 //     alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
      error("Fatal Error in Operation " + (sectionId + 1) + ": Tool-Rotation detected but this post only supports 3 Axis");
      }
   setRotation(remaining);

   forceAny();


   // If the machine has coolant, write M8/M7 or M9
   if (properties.hasCoolant)
      {
      if (isLaser || isPlasma)
         setCoolant(1) // always turn it on since plasma tool has no coolant option in fusion
         else
            setCoolant(tool.coolant); // use tool setting
      }

   if (isLaser && properties.UseZ)
      writeBlock(gMotionModal.format(0), zOutput.format(0));
   isNewfile = false;
   //writeComment("onSection end");
   }

function onDwell(seconds)
   {
   if (seconds > 0.0)
      writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
   }

function onSpindleSpeed(spindleSpeed)
   {
   writeBlock(sOutput.format(spindleSpeed));
   gMotionModal.reset(); // force a G word after a spindle speed change to keep CONTROL happy
   }

function onRadiusCompensation()
   {
   var radComp = getRadiusCompensation();
   var sectionId = getCurrentSectionId();
   if (radComp != RADIUS_COMPENSATION_OFF)
      {
      var radComp = "Error RadiusCompensation is not supported in GRBL - Change RadiusCompensation in CAD/CAM software to Off/Center/Computer";
      //      alert("Error", "RadiusCompensation is not supported in GRBL - Change RadiusCompensation in CAD/CAM software to Off/Center/Computer");
      warning(radComp);
      writeComment(radComp);
      error("Fatal Error in Operation " + (sectionId + 1) + ": RadiusCompensation is found in CAD file but is not supported in GRBL");
      return;
      }
   }

function onRapid(_x, _y, _z)
   {
   haveRapid = true;
   if (debug) writeComment("onRapid");
   if (!isLaser && !isPlasma)
      {
      var x = xOutput.format(_x);
      var y = yOutput.format(_y);
      var z = zOutput.format(_z);

      if (x || y || z)
         {
         writeBlock(gMotionModal.format(0), x, y, z);
         feedOutput.reset();
         }
      }
   else
      {
      if (_z > Zmax) // store max z value for ending
         Zmax = _z;
      var x = xOutput.format(_x);
      var y = yOutput.format(_y);
      var z = "";
      if (isPlasma && properties.UseZ)  // laser does not move Z during cuts
         {
         z = zOutput.format(_z);
         }
      if (isPlasma && properties.UseZ && (xyzFormat.format(_z) == xyzFormat.format(topHeight)) )
         {
         if (debug) writeComment("onRapid skipping Z motion");
         if (x || y)
            writeBlock(gMotionModal.format(0), x, y);
         zOutput.reset();   // force it on next command
         }
      else if (x || y || z)
         writeBlock(gMotionModal.format(0), x, y, z);
      }
   }

function onLinear(_x, _y, _z, feed)
   {
   //if (debug) writeComment("onLinear " + haveRapid);
   if (powerOn || haveRapid)   // do not reset if power is off - for laser G0 moves
      {
      xOutput.reset();
      yOutput.reset(); // always output x and y else arcs go mad
      }
   var x = xOutput.format(_x);
   var y = yOutput.format(_y);
   var f = feedOutput.format(feed);
   if (!isLaser && !isPlasma)
      {
      var z = zOutput.format(_z);

      if (x || y || z)
         {
         linmove = 1;          // have to have a default!
         if (!haveRapid && z)  // if z is changing
            {
            if (_z < retractHeight) // compare it to retractHeight, below that is G1, >= is G0
               linmove = 1;
            else
               linmove = 0;
            if (debug && (linmove == 0)) writeComment("NOrapid");
            }
         writeBlock(gMotionModal.format(linmove), x, y, z, f);
         }
      else if (f)
         {
         if (getNextRecord().isMotion())
            {
            feedOutput.reset(); // force feed on next line
            }
         else
            {
            writeBlock(gMotionModal.format(1), f);
            }
         }
      }
   else
      {
      // laser, plasma
      if (x || y)
         {
         if (haveRapid)
            {
            // this is the old process when we have rapids inserted by onRapid
            var z = properties.UseZ ? zOutput.format(_z) : "";
            var s = sOutput.format(cutPower);
            if (isPlasma && !powerOn) // plasma does some odd routing that should be rapid
               writeBlock(gMotionModal.format(0), x, y, z, f, s);
            else
               writeBlock(gMotionModal.format(1), x, y, z, f, s);
            }
         else
            {
            // this is the new process when we dont have onRapid but GRBL requires G0 moves for noncutting laser moves
            var z = properties.UseZ ? zOutput.format(0) : "";
            var s = sOutput.format(cutPower);
            if (powerOn)
               writeBlock(gMotionModal.format(1), x, y, z, f, s);
            else
               writeBlock(gMotionModal.format(0), x, y, z, f, s);
            }

         }
      }
   }

function onRapid5D(_x, _y, _z, _a, _b, _c)
   {
   var rapid5D =   "Error Tool-Rotation detected - this post only supports 3 Axis";
//   alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
   warning(rapid5D);
   writeComment(rapid5D);
   error("Tool-Rotation detected but GRBL only supports 3 Axis");
   }

function onLinear5D(_x, _y, _z, _a, _b, _c, feed)
   {
   var linear5D = "Error Tool-Rotation detected - this post only supports 3 Axis";
 //  alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
   warning(linear5D);
   writeComment(linear5D);
   error("Tool-Rotation detected but GRBL only supports 3 Axis");
   }

function onCircular(clockwise, cx, cy, cz, x, y, z, feed)
   {
   var start = getCurrentPosition();
   xOutput.reset(); // always have X and Y, Z will output of it changed
   yOutput.reset();

   // arcs smaller than bitradius always have significant radius errors, so get radius and linearize them (because we cannot change minimumCircularRadius here)
   // note that larger arcs still have radius errors, but they are a much smaller percentage of the radius
   var rad = Math.sqrt(Math.pow(start.x - cx,2) + Math.pow(start.y - cy, 2));
   if (properties.linearizeSmallArcs &&  (rad < toolRadius))
      {
      //writeComment("linearizing arc radius " + round(rad,4) + " toolRadius " + round(toolRadius,3));
      linearize(tolerance);
      return;
      }
   if (isFullCircle())
      {
      writeComment("full circle");
      linearize(tolerance);
      return;
      }
   else
      {
      if (isPlasma && !powerOn)
         linearize(tolerance * 4); // this is a rapid move so tolerance can be increased for faster motion and fewer lines of code
      else
         switch (getCircularPlane())
            {
            case PLANE_XY:
               if (!isLaser && !isPlasma)
                  writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
               else
                  {
                  zo = properties.UseZ ? zOutput.format(z) : "";
                  writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zo, iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
                  }
               break;
            case PLANE_ZX:
               if (!isLaser)
                  writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
               else
                  linearize(tolerance);
               break;
            case PLANE_YZ:
               if (!isLaser)
                  writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
               else
                  linearize(tolerance);
               break;
            default:
               linearize(tolerance);
            }
      }
   }

function onSectionEnd()
   {
   writeln("");
   // writeBlock(gPlaneModal.format(17));
   if (isRedirecting())
      {
      if (!isLastSection() && properties.generateMultiple && (tool.number != getNextSection().getTool().number) || (isLastSection() && !isFirstSection()))
         {
         writeln("");
         onClose();
         closeRedirection();
         }
      }
   //if (properties.hasCoolant)
   //   setCoolant(0);
   forceAny();
   }

function onClose()
   {
   writeBlock(gAbsIncModal.format(90));   // Set to absolute coordinates for the following moves
   if (!isLaser && !isPlasma)
      {
      gMotionModal.reset();  // for ease of reading the code always output the G0 words
      writeZretract();
      //writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + xyzFormat.format(toPreciseUnit(properties.machineHomeZ, MM)));  // Retract spindle to Machine Z Home
      }
   writeBlock(mFormat.format(5));                              // Stop Spindle
   if (properties.hasCoolant)
      {
      setCoolant(0);                           // Stop Coolant
      }
   //onDwell(properties.spindleOnOffDelay);                    // Wait for spindle to stop
   gMotionModal.reset();
   if (!isLaser && !isPlasma)
      {
      if (properties.gotoMCSatend)    // go to MCS home
         {
         writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0),
                    "X" + xyzFormat.format(toPreciseUnit(properties.machineHomeX, MM)),
                    "Y" + xyzFormat.format(toPreciseUnit(properties.machineHomeY, MM)));
         }
      else      // go to WCS home
         {
         writeBlock(gAbsIncModal.format(90), gMotionModal.format(0),
                    "X" + xyzFormat.format(toPreciseUnit(properties.machineHomeX, MM)),
                    "Y" + xyzFormat.format(toPreciseUnit(properties.machineHomeY, MM)));
         }
      }
   else     // laser
      {
      if (properties.UseZ)
         {
         if (isLaser)
            writeBlock( gAbsIncModal.format(90), gFormat.format(53),
                        gMotionModal.format(0), zOutput.format(toPreciseUnit(properties.machineHomeZ, MM)) );
         if (isPlasma)
            {
            xOutput.reset();
            yOutput.reset();
            if (properties.gotoMCSatend)    // go to MCS home
               {
               writeBlock( gAbsIncModal.format(90), gFormat.format(53),
                           gMotionModal.format(0),
                           zOutput.format(toPreciseUnit(properties.machineHomeZ, MM)) );
               writeBlock( gAbsIncModal.format(90), gFormat.format(53),
                           gMotionModal.format(0),
                           xOutput.format(toPreciseUnit(properties.machineHomeX, MM)),
                           yOutput.format(toPreciseUnit(properties.machineHomeY, MM)) );
               }
            else
               writeBlock(gMotionModal.format(0), xOutput.format(0), yOutput.format(0));
            }
         }
      }
   writeBlock(mFormat.format(30));  // Program End
   //writeln("%");                    // EndOfFile marker
   }

function onTerminate()
   {
   // If we are generating multiple files, copy first file to add # of #
   // Then remove first file and recreate with file list - sharmstr
   if (filesToGenerate > 1)
      {
      var outputPath = getOutputPath();
      var outputFolder = FileSystem.getFolderPath(getOutputPath());
      var programFilename = FileSystem.getFilename(outputPath);
      FileSystem.copyFile(outputPath, FileSystem.replaceExtension(outputPath, fileIndexFormat.format(1) + 'of' + filesToGenerate + '.' + extension));
      FileSystem.remove(outputPath);
      var file = new TextFile(outputFolder + "\\" + programFilename, true, "ansi");
      file.writeln("The following gcode files were created: ");
      for (var i = 0; i < filesToGenerate; ++i)
         {
         file.writeln(programName + '.' + fileIndexFormat.format(i + 1) + 'of' + filesToGenerate + '.' + extension);
         }
      file.close();
      }
   }

function onCommand(command)
   {
   if (debug ) writeComment("onCommand " + command);
   switch (command)
      {
      case COMMAND_STOP: // - Program stop (M00)
         writeComment("Program stop (M00)");
         writeBlock(mFormat.format(0));
         break;
      case COMMAND_OPTIONAL_STOP: // - Optional program stop (M01)
         writeComment("Optional program stop (M01)");
         writeBlock(mFormat.format(1));
         break;
      case COMMAND_END: // - Program end (M02)
         writeComment("Program end (M02)");
         writeBlock(mFormat.format(2));
         break;
      case COMMAND_POWER_OFF:
         //writeComment("power off");
         if (!haveRapid)
            writeln("");
         powerOn = false;
         if (isPlasma)
            writeBlock(mFormat.format(5));
         break;
      case COMMAND_POWER_ON:
         //writeComment("power ON");
         if (!haveRapid)
            writeln("");
         powerOn = true;
         if (isPlasma)
            {
            if (properties.UseZ)
               {
               if (properties.plasma_usetouchoff)
                  {
                  writeln("");
                  writeBlock( "G38.2" , zOutput.format(toPreciseUnit(-plasma_probedistance,MM)), feedOutput.format(toPreciseUnit(plasma_proberate,MM)));
                  if (debug) writeComment("touch offset "  + xyzFormat.format(properties.plasma_touchoffOffset) );
                  writeBlock( gMotionModal.format(10), "L20" , zOutput.format(toPreciseUnit(-properties.plasma_touchoffOffset,MM)) );
                  feedOutput.reset();
                  }
               // move to pierce height
               if (debug)
                  writeBlock( gMotionModal.format(0), zOutput.format(plasma_pierceHeight) , " ; pierce height" );
               else
                  writeBlock( gMotionModal.format(0), zOutput.format(plasma_pierceHeight));
               }
            writeBlock(mFormat.format(3), sOutput.format(cutPower));
            }
         break;
      }
   // for other commands see https://cam.autodesk.com/posts/reference/classPostProcessor.html#af3a71236d7fe350fd33bdc14b0c7a4c6
   if (debug) writeComment("onCommand end");
   }

function onParameter(name, value)
   {
   //if (debug) writeComment("onParameter =" + name + "= " + value);   // (onParameter =operation:retractHeight value= :5)
   name = name.replace(" ","_");  // dratted indexOF cannot have spaces in it!
   if ( (name.indexOf("retractHeight_value") >= 0 ) )   // == "operation:retractHeight value")
      {
      retractHeight = value;
      if (debug) writeComment("retractHeight = "+retractHeight);
      }
   if (name.indexOf("operation:clearanceHeight_value") >= 0)
      {
      clearanceHeight = value;
      if (debug) writeComment("clearanceHeight = "+clearanceHeight);
      }

   if (name.indexOf("movement:lead_in") !== -1)
      {
      leadinRate = value;
      if (debug && isPlasma) writeComment("leadinRate set " + leadinRate);
      }

   if (name.indexOf("operation:topHeight_value") >= 0)
      {
      topHeight = value;
      if (debug && isPlasma) writeComment("topHeight set " + topHeight);
      }
   // (onParameter =operation:pierceClearance= 1.5)    for plasma
   if (name == 'operation:pierceClearance')
      plasma_pierceHeight = value;
   if ((name == 'action') && (value == 'pierce'))
      {
      if (debug) writeComment('action pierce');
      onDwell(properties.spindleOnOffDelay);
      if (properties.UseZ) // done a probe and/or pierce, now lower to cut height
         {
         writeBlock( gMotionModal.format(1) , zOutput.format(topHeight) , feedOutput.format(leadinRate) );
         gMotionModal.reset();
         }
      }
   }

function round(num,digits)
   {
   return toFixedNumber(num,digits,10)
   }

function toFixedNumber(num, digits, base)
   {
   var pow = Math.pow(base||10, digits);  // cleverness found on web
   return Math.round(num*pow) / pow;
   }

// set the coolant mode from the tool value
function setCoolant(coolval)
   {
   if ( debug) writeComment("setCoolant " + coolval);
   // 0 if off, 1 is flood, 2 is mist, 7 is both
   switch (coolval)
      {
      case 0:
         if (coolantIsOn != 0)
            writeBlock(mFormat.format(9)); // off
         coolantIsOn = 0;
         break;
      case 1:
         if (coolantIsOn == 2)
            writeBlock(mFormat.format(9)); // turn mist off
         writeBlock(mFormat.format(8)); // flood
         coolantIsOn = 1;
         break;
      case 2:
         writeComment("Mist coolant on pin A3. special GRBL compile for this.");
         if (coolantIsOn == 1)
            writeBlock(mFormat.format(9)); // turn flood off
         writeBlock(mFormat.format(7)); // mist
         coolantIsOn = 2;
         break;
      case 7:  // flood and mist
         writeBlock(mFormat.format(8)); // flood
         writeBlock(mFormat.format(7)); // mist
         coolantIsOn = 7;
         break;
      default:
         var floodMismatch = "Warning Coolant option not understood: " + coolval;
         writeComment("Coolant option not understood: " + coolval);
         warning(floodMismatch);
         error("Warning", "Coolant option not understood: " + coolval);
   //      alert("Warning", "Coolant option not understood: " + coolval);
         coolantIsOn = 0;
      }
   if ( debug) writeComment("setCoolant end");
   }
