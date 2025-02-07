// repo is javascript
function rpm2dial(rpm)
	{
	/* translates an RPM for the spindle into a dial value, eg. for the Makita RT0700 and Dewalt 611 routers
	// additionally, check that spindle rpm is between minimum and maximum of what our spindle can do
	// remove // from alert if neccessary
	// array which maps spindle speeds to router dial settings,
	   according to Makita RT0700 Manual : 1=10000, 2=12000, 3=17000, 4=22000, 5=27000, 6=30000
    */
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
