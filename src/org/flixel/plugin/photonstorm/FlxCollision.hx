/**
 * FlxCollision
 * -- Part of the Flixel Power Tools set
 * 
 * v1.6 Fixed bug in pixelPerfectCheck that stopped non-square rotated objects from colliding properly (thanks to joon on the flixel forums for spotting)
 * v1.5 Added createCameraWall
 * v1.4 Added pixelPerfectPointCheck()
 * v1.3 Update fixes bug where it wouldn't accurately perform collision on AutoBuffered rotated sprites, or sprites with offsets
 * v1.2 Updated for the Flixel 2.5 Plugin system
 * 
 * @version 1.6 - October 8th 2011
 * @link http://www.photonstorm.com
 * @author Richard Davey / Photon Storm
*/

package org.flixel.plugin.photonstorm;

import flash.display.BitmapData;
import flash.display.BlendMode;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import org.flixel.FlxCamera;
import org.flixel.FlxG;
import org.flixel.FlxGroup;
import org.flixel.FlxSprite;
import org.flixel.FlxTileblock;
import org.flixel.util.FlxColor;
import org.flixel.util.FlxRect;
import org.flixel.util.FlxMath;

class FlxCollision 
{
	public static var debug:BitmapData = new BitmapData(1, 1, false);
	
	public static var CAMERA_WALL_OUTSIDE:Int = 0;
	public static var CAMERA_WALL_INSIDE:Int = 1;
	
	/**
	 * A Pixel Perfect Collision check between two FlxSprites.
	 * It will do a bounds check first, and if that passes it will run a pixel perfect match on the intersecting area.
	 * Works with rotated and animated sprites.
	 * It's extremly slow on cpp targets, so I don't recommend you to use it on them.
	 * Not working on neko target and awfully slows app down
	 * 
	 * @param	contact			The first FlxSprite to test against
	 * @param	target			The second FlxSprite to test again, sprite order is irrelevant
	 * @param	alphaTolerance	The tolerance value above which alpha pixels are included. Default to 255 (must be fully opaque for collision).
	 * @param	camera			If the collision is taking place in a camera other than FlxG.camera (the default/current) then pass it here
	 * 
	 * @return	Boolean True if the sprites collide, false if not
	 */
	public static function pixelPerfectCheck(contact:FlxSprite, target:FlxSprite, alphaTolerance:Int = 255, camera:FlxCamera = null):Bool
	{
		var pointA:Point = new Point();
		var pointB:Point = new Point();
		
		if (camera != null)
		{
			pointA.x = contact.x - Std.int(camera.scroll.x * contact.scrollFactor.x) - contact.offset.x;
			pointA.y = contact.y - Std.int(camera.scroll.y * contact.scrollFactor.y) - contact.offset.y;
			
			pointB.x = target.x - Std.int(camera.scroll.x * target.scrollFactor.x) - target.offset.x;
			pointB.y = target.y - Std.int(camera.scroll.y * target.scrollFactor.y) - target.offset.y;
		}
		else
		{
			pointA.x = contact.x - Std.int(FlxG.camera.scroll.x * contact.scrollFactor.x) - contact.offset.x;
			pointA.y = contact.y - Std.int(FlxG.camera.scroll.y * contact.scrollFactor.y) - contact.offset.y;
			
			pointB.x = target.x - Std.int(FlxG.camera.scroll.x * target.scrollFactor.x) - target.offset.x;
			pointB.y = target.y - Std.int(FlxG.camera.scroll.y * target.scrollFactor.y) - target.offset.y;
		}
		#if flash
		var boundsA:Rectangle = new Rectangle(pointA.x, pointA.y, contact.framePixels.width, contact.framePixels.height);
		var boundsB:Rectangle = new Rectangle(pointB.x, pointB.y, target.framePixels.width, target.framePixels.height);
		#else
		var boundsA:Rectangle = new Rectangle(pointA.x, pointA.y, contact.frameWidth, contact.frameHeight);
		var boundsB:Rectangle = new Rectangle(pointB.x, pointB.y, target.frameWidth, target.frameHeight);
		#end
		var intersect:Rectangle = boundsA.intersection(boundsB);
		
		if (intersect.isEmpty() || intersect.width == 0 || intersect.height == 0)
		{
			return false;
		}
		
		//	Normalise the values or it'll break the BitmapData creation below
		intersect.x = Math.floor(intersect.x);
		intersect.y = Math.floor(intersect.y);
		intersect.width = Math.ceil(intersect.width);
		intersect.height = Math.ceil(intersect.height);
		
		if (intersect.isEmpty())
		{
			return false;
		}
		
		//	Thanks to Chris Underwood for helping with the translate logic :)
		var matrixA:Matrix = new Matrix();
		matrixA.translate(-(intersect.x - boundsA.x), -(intersect.y - boundsA.y));
		
		var matrixB:Matrix = new Matrix();
		matrixB.translate(-(intersect.x - boundsB.x), -(intersect.y - boundsB.y));
		
		#if !flash
		contact.drawFrame();
		target.drawFrame();
		#end
		
		var testA:BitmapData = contact.framePixels;
		var testB:BitmapData = target.framePixels;
		var overlapArea:BitmapData = new BitmapData(Std.int(intersect.width), Std.int(intersect.height), false);
		#if flash
		overlapArea.draw(testA, matrixA, new ColorTransform(1, 1, 1, 1, 255, -255, -255, alphaTolerance), BlendMode.NORMAL);
		overlapArea.draw(testB, matrixB, new ColorTransform(1, 1, 1, 1, 255, 255, 255, alphaTolerance), BlendMode.DIFFERENCE);
		#else
		// TODO: try to fix this method for neko target
		var overlapWidth:Int = overlapArea.width;
		var overlapHeight:Int = overlapArea.height;
		var targetX:Int;
		var targetY:Int;
		var pixelColor:Int;
		var pixelAlpha:Int;
		var transformedAlpha:Int;
		var maxX:Int = testA.width + 1;
		var maxY:Int = testA.height + 1;
		for (i in 0...(maxX))
		{
			targetX = Math.floor(i + matrixA.tx);
			if (targetX >= 0 && targetX < maxX)
			{
				for (j in 0...(maxY))
				{
					targetY = Math.floor(j + matrixA.ty);
					if (targetY >= 0 && targetY < maxY)
					{
						pixelColor = testA.getPixel32(i, j);
						pixelAlpha = (pixelColor >> 24) & 0xFF;
						if (pixelAlpha >= alphaTolerance)
						{
							overlapArea.setPixel32(targetX, targetY, 0xffff0000);
						}
						else
						{
							overlapArea.setPixel32(targetX, targetY, FlxColor.WHITE);
						}
					}
				}
			}
		}

		maxX = testB.width + 1;
		maxY = testB.height + 1;
		var secondColor:Int;
		for (i in 0...(maxX))
		{
			targetX = Math.floor(i + matrixB.tx);
			if (targetX >= 0 && targetX < maxX)
			{
				for (j in 0...(maxY))
				{
					targetY = Math.floor(j + matrixB.ty);
					if (targetY >= 0 && targetY < maxY)
					{
						pixelColor = testB.getPixel32(i, j);
						pixelAlpha = (pixelColor >> 24) & 0xFF;
						if (pixelAlpha >= alphaTolerance)
						{
							secondColor = overlapArea.getPixel32(targetX, targetY);
							if (secondColor == 0xffff0000)
							{
								overlapArea.setPixel32(targetX, targetY, 0xff00ffff);
							}
							else
							{
								overlapArea.setPixel32(targetX, targetY, 0x00000000);
							}
						}
					}
				}
			}
		}
		
		#end
		
		//	Developers: If you'd like to see how this works enable the debugger and display it in your game somewhere.
		debug = overlapArea;
		
		var overlap:Rectangle = overlapArea.getColorBoundsRect(0xffffffff, 0xff00ffff);
		overlap.offset(intersect.x, intersect.y);
		
		if (overlap.isEmpty())
		{
			return false;
		}
		else
		{
			return true;
		}
		
		return false;
	}
	
	/**
	 * A Pixel Perfect Collision check between a given x/y coordinate and an FlxSprite<br>
	 * 
	 * @param	pointX			The x coordinate of the point given in local space (relative to the FlxSprite, not game world coordinates)
	 * @param	pointY			The y coordinate of the point given in local space (relative to the FlxSprite, not game world coordinates)
	 * @param	target			The FlxSprite to check the point against
	 * @param	alphaTolerance	The alpha tolerance level above which pixels are counted as colliding. Default to 255 (must be fully transparent for collision)
	 * 
	 * @return	Boolean True if the x/y point collides with the FlxSprite, false if not
	 */
	public static function pixelPerfectPointCheck(pointX:Int, pointY:Int, target:FlxSprite, alphaTolerance:Int = 255):Bool
	{
		//	Intersect check
		if (FlxMath.pointInCoordinates(pointX, pointY, Math.floor(target.x), Math.floor(target.y), Std.int(target.width), Std.int(target.height)) == false)
		{
			return false;
		}
		
	#if flash
		//	How deep is pointX/Y within the rect?
		var test:BitmapData = target.framePixels;
	#else
		var test:BitmapData = target.getFlxFrameBitmapData();
	#end
		var pixelAlpha:Int = 0;  
		pixelAlpha = FlxColor.getAlpha(test.getPixel32(Math.floor(pointX - target.x), Math.floor(pointY - target.y)));
		
	#if !flash
		pixelAlpha = Std.int(pixelAlpha * target.alpha);
	#end
		
		//	How deep is pointX/Y within the rect?
		if (pixelAlpha >= alphaTolerance)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	/**
	 * Creates a "wall" around the given camera which can be used for FlxSprite collision
	 * 
	 * @param	camera				The FlxCamera to use for the wall bounds (can be FlxG.camera for the current one)
	 * @param	placement			CAMERA_WALL_OUTSIDE or CAMERA_WALL_INSIDE
	 * @param	thickness			The thickness of the wall in pixels
	 * @param	adjustWorldBounds	Adjust the FlxG.worldBounds based on the wall (true) or leave alone (false)
	 * 
	 * @return	FlxGroup The 4 FlxTileblocks that are created are placed into this FlxGroup which should be added to your State
	 */
	public static function createCameraWall(camera:FlxCamera, placement:Int, thickness:Int, adjustWorldBounds:Bool = false):FlxGroup
	{
		var left:FlxTileblock = null;
		var right:FlxTileblock = null;
		var top:FlxTileblock = null;
		var bottom:FlxTileblock = null;
		
		switch (placement)
		{
			case FlxCollision.CAMERA_WALL_OUTSIDE:
				left = new FlxTileblock(Math.floor(camera.x - thickness), Math.floor(camera.y + thickness), thickness, camera.height - (thickness * 2));
				right = new FlxTileblock(Math.floor(camera.x + camera.width), Math.floor(camera.y + thickness), thickness, camera.height - (thickness * 2));
				top = new FlxTileblock(Math.floor(camera.x - thickness), Math.floor(camera.y - thickness), camera.width + thickness * 2, thickness);
				bottom = new FlxTileblock(Math.floor(camera.x - thickness), camera.height, camera.width + thickness * 2, thickness);
				
				if (adjustWorldBounds)
				{
					FlxG.worldBounds = new FlxRect(camera.x - thickness, camera.y - thickness, camera.width + thickness * 2, camera.height + thickness * 2);
				}
				
			case FlxCollision.CAMERA_WALL_INSIDE:
				left = new FlxTileblock(Math.floor(camera.x), Math.floor(camera.y + thickness), thickness, camera.height - (thickness * 2));
				right = new FlxTileblock(Math.floor(camera.x + camera.width - thickness), Math.floor(camera.y + thickness), thickness, camera.height - (thickness * 2));
				top = new FlxTileblock(Math.floor(camera.x), Math.floor(camera.y), camera.width, thickness);
				bottom = new FlxTileblock(Math.floor(camera.x), camera.height - thickness, camera.width, thickness);
				
				if (adjustWorldBounds)
				{
					FlxG.worldBounds = new FlxRect(camera.x, camera.y, camera.width, camera.height);
				}
		}
		
		var result:FlxGroup = new FlxGroup(4);
		
		result.add(left);
		result.add(right);
		result.add(top);
		result.add(bottom);
		
		return result;
	}
}