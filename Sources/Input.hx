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
    public var clickListeners:Array<(button:Int)->Void> = [];
    public var forwardsListeners:Array<()->Void> = [];
    public var leftMouseButtonDown = false;
    public var rightMouseButtonDown = false;

    public var space = false;
    public var shift = false;

    public function new(camera:Camera) {

		Mouse.get().notify(
            function mouseDown(b,x,y){
                focused=true;
                Mouse.get().lock();

                if (b == 0)
                    leftMouseButtonDown = true;
                if (b == 1)
                    rightMouseButtonDown = true;

                for (listener in clickListeners)
                    listener(b);
            },
            function(b,x,y){
                if (b == 0)
                    leftMouseButtonDown = false;
                if (b == 1)
                    rightMouseButtonDown = false;
            },
            function(x,y,dx,dy){
                if (!focused)
                    return;
                camera.horizontalAngle -= dx/400;
                camera.verticalAngle -= dy/400;
                camera.verticalAngle = Math.max(-Math.PI/2+0.01, Math.min(camera.verticalAngle, Math.PI/2-0.001));
            }, function onScroll(delta){
            }
        );

		Keyboard.get().notify(function down(key){
			if (key == W) {
                forwards = true;
                for (listener in forwardsListeners)
                    listener();
            }
			if (key == A) {	left = true; }
			if (key == S) {	backwards = true; }
            if (key == D) {	right = true; }
            if (key == Space) {	space = true; jumpAttemptCallback(); }
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