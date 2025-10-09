/*
CNC3D / Nighthawk

***CHANGELOG***
10-04-2024	    - 	Removed read-only "power" variable
17-04-2024	    -	Removed "alert" function replaced with "warning"
			            Added Spindle/Router to machine properties
		 	            Removed warning popup for WCS offset and replaced with warning message in GCODE comments when offset set to zero
09-08-2024      - Added multiple tool error checking
                        Reformatted tool information for easier access for Commander
    
				


*/

description = "CNC3D - Nighthawk - GRBL";
vendor = "CNC3D PTY LTD";
vendorUrl = "http://www.cnc3d.com.au";
model = "CNC3D QueenBee, QB2, YouCarve, Metal Storm, SharpCNC";
obversion = '1.03';										// date updated 09-08-2024
longDescription = description + " : Post" + obversion; 	// adds description to post library dialog box
legal = "CNC3D PTY LTD Australia";
certificationLevel = 2;


extension = "nc";										// file extension of the gcode file
setCodePage("ascii");									// character set of the gcode file
//setEOL(CRLF);											// end-of-line type : default for Windows OS is CRLF (so that's why this line is commented out), change to CR, LF, CRLF or LFCR if you are on another OS...

var permittedCommentChars = " ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,=_-*/\\:";
capabilities = CAPABILITY_MILLING | CAPABILITY_JET;		// intended for a CNC, so Milling, or 2D machines, such as lasers..
tolerance = spatial(0.002, MM);							// when linearizing a move, fusion will create linear segments which are within this amount of the actual path... Smaller values will result in more and smaller linear segments. GRBL.cps uses 0.002 mm
minimumChordLength = spatial(0.25, MM);					// minimum lenght of an arc, if Fusion needs a short arc, it will linearize... Problem with very small arcs is that rounding errors resulting from limited number of digits, result in GRBL error 33
minimumCircularRadius = spatial(0.5, MM);				// minimum radius of an arc.. Fusion will linearize if you need a smaller arc. Same problem with rounding errors as above
maximumCircularRadius = spatial(1000, MM);
minimumCircularSweep = toRad(0.1);
maximumCircularSweep = toRad(350);						// maximum angle of an arc. 350 prevents Fusion from outputting full circles.. Although GRBL can do this (with some special GCODE syntax) it is more robust to not do it and stick to standard G2 G3 use.. Fusion will split a longer arc into multiple smaller G2 G3 arcs
allowHelicalMoves = true;
allowedCircularPlanes = (1 << PLANE_XY) | (1 << PLANE_ZX) | (1 << PLANE_YZ);	// This is safer (instead of using 'undefined'), as it enumerates the allowed planes in GRBL



// define the custom property groups

groupDefinitions = {
	machineHomePosition: {title: "G53 Machine Co-Ords Finish Position", description: "G53 Finish Position - Used when Finish At Job Start is not ticked", collapsed:true, order:45},
	jobHomePosition: {title:"G54 Job Co-Ords Finish Position", description: "G54 Finish Position - Used when Finish At Job Start is ticked", collapsed:false, order:25}

	};

	
// user-defined properties : defaults are set, but they can be changed from a dialog box in Fusion when doing a post.
properties =
	{

	
	spindleDwell: {
		title      : "Spindle On/Off Delay",
		description: "Dwell time to allow spindle to get up to speed",
		group      : "preferences",
		type       : "number",
		value      : 10.0,
		scope      : "post"
	  },

    spindleTwoDirections: {
		title      : "Spindle Two Directions",
		description: "If ticked: Spindle can run forward and reverse commanded by software",
		group      : "preferences",
		type       : "boolean",
		value      : false,
		scope      : "post"
	  },

    routerType: {
		title      : "Spindle Type",
		description: "Does your machine have a spindle or a router eg: Makita",
		group      : "preferences",
		type       : "enum",
		values     : [
			{title:"Spindle", id:"spindle"},
			{title:"Router", id:"router"}
		],
		value		: "spindle",
		scope		: "post"
	},     

    finishAtJobStart: {
		title      : "Finish At Job Start (G54)",
		description: "If ticked: uses G54 instead of G53 for the coordinates used where the machine will move at the end of the job",
		group      : "preferences",
		type       : "boolean",
		value      : true,
		scope      : "post"
	  },  

	retractStrat: {
		title		: "Retraction Setting",
		description	: "Z moves before and after job for G54 Only. 'Clearance Height' uses clearance height value. 'G28' uses job zero + user offset",
		group		: "jobHomePosition",
		type		: "enum",
		values     	: [
			{title:"G28", id:"G28"},
			{title:"Clearance Height", id:"clearanceHeight"}
		],
		value		: "clearanceHeight",
		scope		: "post"
	  }, 

    hasCoolant: {
		title      : "Has Coolant",
		description: "If Ticked: Machine uses the coolant output M8 M9 will be sent. If not ticked: coolant output not connected, so no M8 M9 will be sent",
		group      : "preferences",
		type       : "boolean",
		value      : false,
		scope      : "post"
	  },
	machineHomeZ: {
		title      : "End Position Z G53",
		description: "Z Position for final movement in Machine Co-ords",
		group      : "machineHomePosition",
		type       : "number",
		value      : 0,
		scope      : "post"
	
	},
	
	machineHomeX: {
		title      : "End Position X G53",
		description: "X Position for final movement in Machine Co-ords",
		group      : "machineHomePosition",
		type       : "number",
		value      : 0,
		scope      : "post"
	  },
	
    machineHomeY: {
		title      : "End Position Y G53",
		description: "Y Position for final movement in Machine Co-ords",
		group      : "machineHomePosition",
		type       : "number",
		value      : 0,
		scope      : "post"
	  },

    jobHomeZ: {
		title      : "Job End Z G54",
		description: "Z Position for final movement in job Co-ords G54",
		group      : "jobHomePosition",
		type       : "number",
		value      : 5,
		scope      : "post"
	  },

    jobHomeX: {
		title      : "Job End X G54",
		description: "X Position for final movement in job Co-ords G54",
		group      : "jobHomePosition",
		type       : "number",
		value      : 0,
		scope      : "post"
	  },

    jobHomeY: {
		title      : "Job End Y G54",
		description: "Y Position for final movement in job Co-ords G54",
		group      : "jobHomePosition",
		type       : "number",
		value      : 0,
		scope      : "post"
	  },


	};

// creation of all kinds of G-code formats - controls the amount of decimals used in the generated G-Code
var gFormat = createFormat({prefix:"G", decimals:0});
var mFormat = createFormat({prefix:"M", decimals:0});

var xyzFormat = createFormat({decimals:(unit == MM ? 4 : 6)});
var abcFormat = createFormat({decimals: 3, forceDecimal: true, scale: DEG});
var feedFormat = createFormat({decimals:(unit == MM ? 1 : 3)});
var rpmFormat = createFormat({decimals:0});
var secFormat = createFormat({decimals:1, forceDecimal:true, trim:false});
var taperFormat = createFormat({decimals:1, scale:DEG});

var xOutput = createVariable({prefix:"X"}, xyzFormat);
var yOutput = createVariable({prefix:"Y"}, xyzFormat);
var zOutput = createVariable({prefix:"Z"}, xyzFormat);
var feedOutput = createVariable({prefix:"F"}, feedFormat);
var sOutput = createVariable({prefix:"S", force:true}, rpmFormat);

var iOutput = createReferenceVariable({prefix:"I"}, xyzFormat);
var jOutput = createReferenceVariable({prefix:"J"}, xyzFormat);
var kOutput = createReferenceVariable({prefix:"K"}, xyzFormat);

var gMotionModal = createModal({}, gFormat); 											// modal group 1 // G0-G3, ...
var gPlaneModal = createModal({onchange:function () {gMotionModal.reset();}}, gFormat); // modal group 2 // G17-19
var gAbsIncModal = createModal({}, gFormat); 											// modal group 3 // G90-91
var gFeedModeModal = createModal({}, gFormat); 											// modal group 5 // G93-94
var gUnitModal = createModal({}, gFormat); 												// modal group 6 // G20-21


function toTitleCase(str)
	{
	// function to reformat a string to 'title case'
	return str.replace(/\w\S*/g, function(txt)
		{
		return txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase();
		});
	}

function rpm2dial(rpm)
	{
	// translates an RPM for the spindle into a dial value, eg. for the Makita RT0700 and Dewalt 611 routers
	// additionally, check that spindle rpm is between minimum and maximum of what our spindle can do
	// remove // from alert if neccessary
	// array which maps spindle speeds to router dial settings,
	// according to Makita RT0700 Manual : 1=10000, 2=12000, 3=17000, 4=22000, 5=27000, 6=30000
	var speeds = [0, 10000, 12000, 17000, 22000, 27000, 30000];

	if (rpm < speeds[1])
		{
		//alert("Warning", rpm + " rpm is below minimum spindle RPM of " + speeds[1] + " rpm");
		var lowRPM = "Warning " + rpm + " rpm is below minimum router RPM of " + speeds[1] + " rpm";
		warning(lowRPM);
		writeComment(lowRPM);
		return 1;
		}

	if (rpm > speeds[speeds.length - 1])
		{
		//alert("Warning", rpm + " rpm is above maximum spindle RPM of " + speeds[speeds.length - 1] + " rpm");
		var highRPM = "Warning " + rpm + " rpm is above maximum router RPM of " + speeds[speeds.length - 1] + " rpm";
		warning(highRPM);
		writeComment(highRPM);
				return (speeds.length - 1);
		}

	var i;
	for (i=1; i < (speeds.length-1); i++)
		{
		if ((rpm >= speeds[i]) && (rpm <= speeds[i+1]))
			{
			return ((rpm - speeds[i]) / (speeds[i+1] - speeds[i])) + i;
			}
		}

	//alert("Error", "Error in calculating router speed dial..");
	var rpmFail = "Error in calculating router speed dial..";
	warning(rpmFail);
	writeComment(rpmFail);
	//error("Fatal Error calculating router speed dial");
	return 0;
	}

function writeBlock()
	{
	writeWords(arguments);
	}

/*function writeComment(text)
	{
	// Remove special characters which could confuse GRBL : $, !, ~, ?, (, )
	// In order to make it simple, I replace everything which is not A-Z, 0-9, space, : , .
	// Finally put everything between () as this is the way GRBL & UGCS expect comments
	writeln("(" + String(text).replace(/[^a-zA-Z\d :=,.]+/g, " ") + ")");
	}*/


function formatComment(text)
   {
   return ("(" + filterText(String(text), permittedCommentChars) + ")");
   }


function writeComment(text)
   {
   // v20 - split the line so no comment is longer than 70 chars
   if (text.length > 70)
      {
      //text = String(text).replace( /[^a-zA-Z\d:=,.]+/g, " "); // remove illegal chars
      text = filterText(text.trim(), permittedCommentChars);
      var bits = text.split(" "); // get all the words
      var out = '';
      for (i = 0; i < bits.length; i++)
         {
         out += bits[i] + " "; // additional space after first line
         if (out.length > 60)           // a long word on the end can take us to 80 chars!
            {
            writeln(formatComment( out.trim() ) );
            out = "";
            }
         }
      if (out.length > 0)
         writeln(formatComment( out.trim() ) );
      }
   else
      writeln(formatComment(text));
   }

function onOpen()
	{

    var multipleToolError;

	// here you set all the properties of your machine, so they can be used later on
	var myMachine = getMachineConfiguration();
	myMachine.setWidth(700);
	myMachine.setDepth(700);
	myMachine.setHeight(120);
	myMachine.setMaximumSpindlePower(255);
	myMachine.setMaximumSpindleSpeed(30000);
	myMachine.setMilling(true);
	myMachine.setTurning(false);
	myMachine.setToolChanger(false);
	myMachine.setNumberOfTools(1);
	myMachine.setNumberOfWorkOffsets(6);
	myMachine.setVendor("CNC3D");
	myMachine.setModel("CNC3D Nighthawk");
	myMachine.setControl("CNC3D Commander");

	

	var productName = getProduct();
	writeComment("Made in : " + productName);
	writeComment("G-Code optimized for " + myMachine.getModel() + " controller using " + myMachine.getControl() );
	writeComment("Post Processor version " + obversion);

	writeln("");

	if (programName)
		{
		writeComment("Program Name : " + programName);
		}
	if (programComment)
		{
		writeComment("Program Comments : " + programComment);
		}

	var numberOfSections = getNumberOfSections();
	writeComment(numberOfSections + " Operation" + ((numberOfSections == 1)?"":"s"));
	writeln("");

	for (var i = 0; i < numberOfSections; ++i)
		{
		         
                var sectioni = getSection(i);
                var tooli = sectioni.getTool();
            
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
                         error( subst(
                                   localize("Using the same tool number for different cutter geometry for operation '%1' and '%2'."),
                                   sectioni.hasParameter("operation-comment") ? sectioni.getParameter("operation-comment") : ("#" + (i + 1)),
                                   sectionj.hasParameter("operation-comment") ? sectionj.getParameter("operation-comment") : ("#" + (j + 1))
                                ) );
                         return;
                         }
                      }
                   else
                      {
                        multipleToolError = true;                        
                      }
                   }

         if (multipleToolError)
            {
                var mte = "MULTIPLE TOOLS DETECTED. Tool changes not supported.";
                warning(mte);
                writeComment(mte);
                error("Fatal Error : Multiple tools detected. This Post Processor does not support tool changes. You should create individual jobs for separate tools");
            }

    
        var section = getSection(i);
		var tool = section.getTool();
		var rpm = section.getMaximumSpindleSpeed();

       // writeComment("T" + tooli.number + ": "+ toTitleCase(getToolTypeName(tool.type)) + " " + tool.numberOfFlutes + " Flutes, Diam = " + xyzFormat.format(tool.diameter) + "mm, Len = " + tool.fluteLength + "mm");

		if (section.hasParameter("operation-comment"))
			{
			writeComment((i+1) + " : " + section.getParameter("operation-comment"));
			}
		else
			{
			writeComment(i+1);
            }


      if (section.workOffset > 0)
         {
		   writeComment(" Work Coordinate System : G" + (section.workOffset + 53));
         }

            if(tool.numberOfFlutes > 1 || 0)
                {
                    var s = "s";
                }
            if(tool.numberOfFlutes == 1)
                {
                    var s = "";
                }

			//add tool info as a comment with tool number linked to section number. Multiple tools in same job will force error in post so this works for Commander as intended GCODE sender to read tool info and display to user
		writeComment(" T" + (i+1) + ": " + toTitleCase(getToolTypeName(tool.type)) + " " + tool.numberOfFlutes + " Flute" + s +", Diam = " + xyzFormat.format(tool.diameter) + "mm, Len = " + tool.fluteLength + "mm");
		if (getProperty("routerType") == "router")
			{
			writeComment(" Router : RPM = " + rpm + ", set router dial to " + rpm2dial(rpm));
			}
		else
			{
			writeComment(" Spindle : RPM = " + rpm);
			}
		var machineTimeInSeconds = section.getCycleTime();
		var machineTimeHours = Math.floor(machineTimeInSeconds / 3600);
		machineTimeInSeconds  = machineTimeInSeconds % 3600;
		var machineTimeMinutes = Math.floor(machineTimeInSeconds / 60);
		var machineTimeSeconds = Math.floor(machineTimeInSeconds % 60);
		var machineTimeText = " Machining time : ";
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
		writeln("");
		}
	writeln("");
    
	writeBlock(gAbsIncModal.format(90));
    writeBlock(gFeedModeModal.format(94));
	writeBlock(gPlaneModal.format(17));
	switch (unit)
		{
		case IN:
			writeBlock(gUnitModal.format(20));
			break;
		case MM:
			writeBlock(gUnitModal.format(21));
			break;
		}

	writeln("");
	
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
	}

function onSection()
	{
	var nmbrOfSections = getNumberOfSections();		// how many operations are there in total
	var sectionId = getCurrentSectionId();			// what is the number of this operation (starts from 0)
	var section = getSection(sectionId);			// what is the section-object for this operation

	
	// check RadiusCompensation setting
	var radComp = getRadiusCompensation();
	var sectionId = getCurrentSectionId();
	if (radComp != RADIUS_COMPENSATION_OFF)
		{
		//alert("Error", "RadiusCompensation is not supported in GRBL - Change RadiusCompensation in CAD/CAM software to Off/Center/Computer");
		var radMSG = "RadiusCompensation is not supported in this PostP - Change RadiusCompensation in CAD/CAM software to Off/Center/Computer";
		warning (radMSG);
		writeComment(radMSG);
		error("Fatal Error in Operation " + (sectionId + 1) + ": RadiusCompensation is found in CAD file but is not supported in this PostP");
		return;
		}
	
	
	// Insert a small comment section to identify the related G-Code in a large multi-operations file
	var comment = "Operation " + (sectionId + 1) + " of " + nmbrOfSections;
	if (hasParameter("operation-comment"))
		{
		comment = comment + " : " + getParameter("operation-comment");
		}
	writeComment(comment);
	writeln("");

	// To be safe (after jogging to whatever position), move the spindle up to a safe  position before going to the initial position
	// At end of a section, spindle is retracted to clearance height, so it is only needed on the first section
	
	if((isFirstSection()) && (getProperty("finishAtJobStart") == false) )
		{
		writeBlock(gAbsIncModal.format(90));	// Set to absolute coordinates
		if (isMilling())
			{
			writeBlock(gFormat.format(53), gMotionModal.format(0), "Z" + xyzFormat.format(getProperty("machineHomeZ")));	// Retract spindle to Machine Z Home
			}
		}
	else if((isFirstSection()) && (getProperty("finishAtJobStart") == true) )
			{
		writeBlock(gAbsIncModal.format(90));	// Set to absolute coordinates
		
		if (getProperty("retractStrat") == "clearanceHeight")
				{
			if (isMilling())
				{
          	 	writeComment("Start/End strategy set to clearance height. If you are getting Soft Limit alarms check the operation clearance height");    
				writeBlock(gFormat.format(54), gMotionModal.format(0), "Z" + xyzFormat.format(section.getParameter('operation:clearanceHeight_value')));	//retract spindle to job clearance height						//(getProperty("jobHomeZ")));	// Retract spindle to Job Z 0
				}
			}
		else if (getProperty("retractStrat") == "G28")	
			{
				if (isMilling())
				{
          	 	writeComment("Start/End strategy set to G28 so user Z offset is used");    
				writeBlock(gFormat.format(54), gMotionModal.format(0), "Z" + xyzFormat.format(getProperty("jobHomeZ")));	// Retract spindle to Job Z 0
				}
			}
		}
	
		// Write the WCS, ie. G54 or higher.. default to WCS1 / G54 if no or invalid WCS in order to prevent using Machine Coordinates G53
	
	if ((section.workOffset < 1) || (section.workOffset > 6))
		{
    	var wcsOffset = "**Warning** Invalid Work Coordinate System. Select WCS 1 to 6 in CAM software. In Fusion360, set the WCS in CAM-workspace | Setup-properties | PostProcess-tab. Default WCS1/G54 selected"
        warning(wcsOffset);
		writeComment(wcsOffset);
	    writeBlock(gFormat.format(54));  // output what we want, G54
		}
   else
       {
	   writeBlock(gFormat.format(53 + section.workOffset));  // use the selected WCS
       }

	var tool = section.getTool();

	// Insert the Spindle start command
	if (tool.clockwise)
		{
		writeBlock(mFormat.format(3), sOutput.format(tool.spindleRPM));
		}
	else if (getProperty("spindleTwoDirections") == true)
		{
		writeBlock(mFormat.format(4), sOutput.format(tool.spindleRPM));
		}
	else
		{
		//alert("Error", "Counter-clockwise Spindle Operation found, but your spindle does not support this");
		var spindleDirec = "***Error*** Counter-clockwise Spindle Operation found, but your spindle does not support this";
		warning(spindleDirec);
		writeComment(spindleDirec);
		error("Fatal Error in Operation " + (sectionId + 1) + ": Counter-clockwise Spindle Operation found, but your spindle does not support this");
		return;
		}

	// Wait some time for spindle to speed up - only on first section, as spindle is not powered down in-between sections
	if(isFirstSection())
		{
		onDwell(getProperty("spindleDwell"));
		}

	// If the machine has coolant, write M8, else write M9
	if (getProperty("hasCoolant") == true)
		{
		if (tool.coolant == COOLANT_FLOOD)
			{
			writeBlock(mFormat.format(8));
			}
		else if (tool.coolant == COOLANT_MIST)
			{
			writeBlock(mFormat.format(7));
			}
		else if (tool.coolant == COOLANT_FLOOD_MIST)
			{
			writeBlock(mFormat.format(7));
			writeBlock(mFormat.format(8));
			}
		else
			{
			writeBlock(mFormat.format(9));
			}
		}

	var remaining = currentSection.workPlane;
	if (!isSameDirection(remaining.forward, new Vector(0, 0, 1)))
		{
		//alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
		var toolRot = "***Error*** Tool-Rotation detected - this PostP only supports 3 Axis"
		warning(toolRot);
		writeComment(toolRot);
		error("Fatal Error in Operation " + (sectionId + 1) + ": Tool-Rotation detected but GRBL only supports 3 Axis");
		}
	setRotation(remaining);

	forceAny();		// this ensures all axis and feed are output at the beginning of the section

	// Rapid move to initial position, first XY, then Z
	var initialPosition = getFramePosition(currentSection.getInitialPosition());
	writeBlock(gAbsIncModal.format(90), gMotionModal.format(0), xOutput.format(initialPosition.x), yOutput.format(initialPosition.y));
	writeBlock(gMotionModal.format(0), zOutput.format(initialPosition.z));
	}

function onDwell(seconds)
	{
	writeBlock(gFormat.format(4), "P" + secFormat.format(seconds));
	}

function onSpindleSpeed(spindleSpeed)
	{
	writeBlock(sOutput.format(spindleSpeed));
	}

function onRapid(_x, _y, _z)
	{
	var x = xOutput.format(_x);
	var y = yOutput.format(_y);
	var z = zOutput.format(_z);
	if (x || y || z)
		{
		writeBlock(gMotionModal.format(0), x, y, z);
		feedOutput.reset();								// after a G0, we will always resend the Feedrate... Is this useful ?
		}
	}

function onLinear(_x, _y, _z, feed)
	{
	var x = xOutput.format(_x);
	var y = yOutput.format(_y);
	var z = zOutput.format(_z);
	var f = feedOutput.format(feed);

	if (x || y || z || f)
		{
		writeBlock(gMotionModal.format(1), x, y, z, f);
		}
	}

function onRapid5D(_x, _y, _z, _a, _b, _c)
	{
		//alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
	warning(toolRot);
	writeComment(toolRot);
	error("Tool-Rotation detected but GRBL only supports 3 Axis");
	}

function onLinear5D(_x, _y, _z, _a, _b, _c, feed)
	{
	//alert("Error", "Tool-Rotation detected - GRBL only supports 3 Axis");
	warning(toolRot);
	writeComment(toolRot);
	error("Tool-Rotation detected but GRBL only supports 3 Axis");
	}

function onCircular(clockwise, cx, cy, cz, x, y, z, feed)
	{
	var start = getCurrentPosition();

	switch (getCircularPlane())
		{
		case PLANE_XY:
			writeBlock(gPlaneModal.format(17), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), jOutput.format(cy - start.y, 0), feedOutput.format(feed));
			break;
		case PLANE_ZX:
			writeBlock(gPlaneModal.format(18), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), iOutput.format(cx - start.x, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
			break;
		case PLANE_YZ:
			writeBlock(gPlaneModal.format(19), gMotionModal.format(clockwise ? 2 : 3), xOutput.format(x), yOutput.format(y), zOutput.format(z), jOutput.format(cy - start.y, 0), kOutput.format(cz - start.z, 0), feedOutput.format(feed));
			break;
		default:
			linearize(tolerance);
		}
	}

function onSectionEnd()
	{
    xOutput.reset();						// resetting, so everything that comes after this section, will get X, Y, Z, F outputted, even if their values did not change..
    yOutput.reset();
    zOutput.reset();
    feedOutput.reset();

	writeln("");							// add a blank line at the end of each section
	}

function onClose()
	{
	if (getProperty("finishAtJobStart") == true)		// job finishes at where it started
		{
		writeBlock(gAbsIncModal.format(90));	// Set to absolute coordinates for the following moves
		if (getProperty("retractStrat") == "clearanceHeight")
		{
			var lastSection = getSection(getNumberOfSections() - 1)

				if (isMilling())						// For CNC we move the Z-axis up, for lasercutter it's not needed
				{
				writeBlock(gAbsIncModal.format(90), gFormat.format(54), gMotionModal.format(0), "Z" + xyzFormat.format(lastSection.getParameter('operation:clearanceHeight_value')));	// Retract spindle to clearance height
				}
			}		

	else if (getProperty("retractStrat") == "G28")	
		{
			if (isMilling())						// For CNC we move the Z-axis up, for lasercutter it's not needed
				{
				writeBlock(gAbsIncModal.format(90), gFormat.format(54), gMotionModal.format(0), "Z" + xyzFormat.format(getProperty("jobHomeZ")));	// Retract spindle to Machine Z Home EDITED TO G54
				}
			
		}	
		writeBlock(mFormat.format(5));																					// Stop Spindle
		if (getProperty("hasCoolant") == true)
			{
			writeBlock(mFormat.format(9));																				// Stop Coolant
			}
		onDwell(getProperty("spindleDwell"));																			// Wait for spindle to stop
		writeBlock(gAbsIncModal.format(90), gFormat.format(54), gMotionModal.format(0), "X" + xyzFormat.format(getProperty("jobHomeX")), "Y" + xyzFormat.format(getProperty("jobHomeY")));	// Return to home position EDITED TO G54
																									
  
		}
	else if (getProperty("finishAtJobStart") == false) // job finishes at absolute position
		{
		writeBlock(gAbsIncModal.format(90));	// Set to absolute coordinates for the following moves
		if (isMilling())						// For CNC we move the Z-axis up, for lasercutter it's not needed
			{
			writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "Z" + xyzFormat.format(getProperty("machineHomeZ")));	// Retract spindle to Machine Z Home
			}
		writeBlock(mFormat.format(5));																					// Stop Spindle
		if (getProperty("hasCoolant") == true)
			{
			writeBlock(mFormat.format(9));																				// Stop Coolant
			}
		onDwell(getProperty("spindleDwell"));																			// Wait for spindle to stop
		writeBlock(gAbsIncModal.format(90), gFormat.format(53), gMotionModal.format(0), "X" + xyzFormat.format(getProperty("machineHomeX")), "Y" + xyzFormat.format(getProperty("machineHomeY")));	// Return to home position

		
		}
	}



