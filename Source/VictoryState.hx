package;

import nme.Assets;
import org.flixel.FlxBasic;
import org.flixel.FlxEmitter;
import org.flixel.FlxG;
import org.flixel.FlxParticle;
import org.flixel.FlxState;
import org.flixel.FlxText;
import org.flixel.FlxTextField;

class VictoryState<T : FlxBasic> extends FlxState<FlxBasic>
{
	private var _timer:Float;
	private var _fading:Bool;

	override public function create():Void
	{
		_timer = 0;
		_fading = false;
		FlxG.flash(0xffd8eba2);
		
		//Gibs emitted upon death
		var gibs:FlxEmitter<FlxParticle> = new FlxEmitter<FlxParticle>(0, -50);
		gibs.setSize(FlxG.width, 0);
		gibs.setXSpeed();
		gibs.setYSpeed(0, 100);
		gibs.setRotation( -360, 360);
		gibs.gravity = 80;
		gibs.makeParticles(FlxAssets.imgSpawnerGibs, 800, 32, true, 0);
		add(gibs);
		gibs.start(false, 0, 0.005);
		
		#if flash
		var text:FlxText = new FlxText(0, FlxG.height / 2 - 35, FlxG.width, "VICTORY\n\nSCORE: " + FlxG.score);
		#else
		var text:FlxTextField = new FlxTextField(0, FlxG.height / 2 - 35, FlxG.width, "VICTORY\n\nSCORE: " + FlxG.score);
		#end
		text.setFormat(null, 16, 0xd8eba2, "center");
		add(text);
	}

	override public function update():Void
	{
		super.update();
		if(!_fading)
		{
			_timer += FlxG.elapsed;
			if((_timer > 0.35) && ((_timer > 10) || FlxG.keys.justPressed("X") || FlxG.keys.justPressed("C")))
			{
				_fading = true;
				if (Mode.SoundOn)
				{
					FlxG.play(Assets.getSound("assets/menu_hit_2" + Mode.SoundExtension));
				}
				
				FlxG.fade(0xff131c1b, 2, false, onPlay);
			}
		}
	}
	
	private function onPlay():Void 
	{
		FlxG.switchState(new PlayState<FlxBasic>());
	}
	
}