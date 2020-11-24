package ;

import kha.input.Keyboard;
import kha.input.Mouse;

class Input {
    public var forwards = false;
    public var backwards = false;
    public var left = false;
    public var right = false;
    public var focused = false;
    public var jumpAttemptCallback:Void->Void = function(){};
    public var clickListeners:Array<()->Void> = [];

    public var space = false;
    public var shift = false;

    public function new(camera:Camera) {

		Mouse.get().notify(
            function mouseDown(b,x,y){
                focused=true;
                Mouse.get().lock();
                for (listener in clickListeners)
                    listener();
            },
            function(b,x,y){
                // Mouse.get().unlock();
            },
            function(x,y,dx,dy){
                if (!focused)
                    return;
                camera.horizontalAngle -= dx/400;
                camera.verticalAngle -= dy/400;
                camera.verticalAngle = Math.max(-Math.PI/2+0.01, Math.min(camera.verticalAngle, 2));
            }, function onScroll(delta){
            }
        );

		Keyboard.get().notify(function down(key){
			if (key == W) {	forwards = true; }
			if (key == A) {	left = true; }
			if (key == S) {	backwards = true; }
            if (key == D) {	right = true; }
            if (key == Space) {	space = true; }
            if (key == Shift) {	shift = true; }

            if (key == Escape) {
                focused = false;
                Mouse.get().unlock();
            }
		}, function up(key){
			if (key == W) {	forwards = false; }
			if (key == A) {	left = false; }
			if (key == S) {	backwards = false; }
            if (key == D) {	right = false; }
            if (key == Space) {	space = false; }
            if (key == Shift) {	shift = false; }
		});
    }
}