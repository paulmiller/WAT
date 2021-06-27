using Godot;
using System;

public class RangeTest : WAT.Test

{
	public override String Title()
	{
		return "Range Assertions";
	}
	
	[Test]
	public void WhenCallingIsInRange()
	{
		const int val = 0;
		const int low = 0;
		const int high = 10;
		Assert.IsInRange(val, low, high, "Then it passes");
	}
	
	[Test]
	public void WhenCallingIsNotInRange()
	{
		const int val = 10;
		const int low = 0;
		const int high = 10;
		Assert.IsNotInRange(val, low, high, "Then it passes");
	}
}
