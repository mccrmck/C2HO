// CH2O AV
(
var pixPath = "pix/".resolveRelative;
var vidsPath = "vids/".resolveRelative;
var sourceImg = "start.jpg".resolveRelative;
var renderName = "3Iter.mov";
var frames = 1000; // 3000

var moshPhoto = { |inPath, action|

	Routine({
		var cond = CondVar();
		var outFile, inFile = File(inPath,"rb");
		var length = inFile.length;
		var array = Int8Array.newClear(length);
		var size = array.size;
		inFile.read(array);

		fork{
			frames.do({ |i|
				var done = false;
				var step = (220 * (i * 0.1).sin.linlin(-1,1,0,1)).asInteger;
				var offset = size * [0.1,0.4,0.7].choose;

				var index = ((offset + step)  % size).asInteger;
				// array[index] = array[index] >> 1 | array[index] << 1;
				// array[index] = array[index] >> 1 & array[index] << 1;
				// array[index] = array[index - 1];
				// array[index] = array[index] - 1 % 127;
				array[index] = array[index].neg;

				cond.signalOne;
				done = true;

				cond.wait{ done };

				i = "000%".format(i + 1);

				outFile = File(pixPath +/+ "img0-%.jpg".format(i.keep(-4)), "wb");
				outFile.write(array);
				outFile.close;
				0.01.wait;                                                                // can this be less time even?
			});

			action.value;
		};
	}).play
};

var moshVideo = { |inPath, outName, action|

	Routine({
		// var cond = CondVar();
		var outFile, inFile = File(vidsPath ++ inPath,"rb");
		var length = inFile.length;
		var array = Int8Array.newClear(length);
		var size = array.size;
		inFile.read(array);

		fork{
			350.do({ |k|
				var index = size.rand;
				// array[index] = -128.rrand(127);
				array[index] = array[index] >> 1;
			});

			outFile = File(vidsPath +/+ outName, "wb");
			outFile.write(array);
			outFile.close;
		};

		action.value;
	}).play
};

var moshFrames = { |pixFolder, iter, action|


	Routine({
		frames.do({ |i|
			var suffix = "000%".format(i + 1);
			var path = pixPath +/+ "img%-%.jpg".format(iter, suffix.keep(-4));
			var outFile, inFile = File(path,"rb");
			var length = inFile.length;
			var array = Int8Array.newClear(length);
			var size = array.size;
			inFile.read(array);

			fork{
				2.do({ |i|
					var step = (220 * (i * 0.1).sin.linlin(-1,1,0,1)).asInteger;
					var offset = size * [0.1,0.9].choose;

					var index = ((offset + step) * [0.2,0.5,0.8].choose) % size;
					// array[index] = array[index] >> 1 | array[index] << 1;
					// array[index] = array[index] >> 1 & array[index] << 1;
					// array[index] = array[index - 1];
					// array[index] = array[index] - 1 % 127;
					array[index] = array[index].neg;

				});
				0.01.wait;
				outFile = File(pixPath +/+ "img%-%.jpg".format(iter + 1, suffix.keep(-4)), "wb");
				outFile.write(array);
				outFile.close;
			};
			0.01.wait;
		});

		action.value;

	}).play;
};

var frames2Video = { |movName, iter|
	var pPath = pixPath.replace(" ","\\ ");
	var vPath = vidsPath.replace(" ","\\ ");

	"ffmpeg -framerate 25 -i %img%-%04d.jpg % ".format(pPath, iter, "%", vPath ++ movName).runInTerminal

};

var video2Frames = { |movName, iter|
	var pPath = pixPath.replace(" ","\\ ");
	var vPath = vidsPath.replace(" ","\\ ");

	"ffmpeg -r 25 -i % %img%-%04d.jpg".format(vPath ++ movName, pPath, iter, "%").runInTerminal
};

var render = { |movName,iter|
	var pPath = pixPath.replace(" ","\\ ");
	var vPath = "renders/".resolveRelative.replace(" ","\\ ");

	"ffmpeg -framerate 25 -i %img%-%04d.jpg % ".format(pPath, iter, "%", vPath ++ movName).runInTerminal

};

Routine({

	var cond = CondVar();
	var iterations = 2;

	// lightly corrupt a .jpg file several times
	moshPhoto.(sourceImg,{ cond.signalOne; "moshed a photo".postln });

	cond.wait { File.exists(pixPath ++ "img0-%.jpg".format(frames)) };

	iterations.do({ |index|

		// make frames into a movie

		frames2Video.("in%.mov".format(index),index);

		70.wait;

		cond.wait { File.exists(vidsPath ++ "in%.mov".format(index)) };

		"made a movie".postln;

		// mosh the movie
		moshVideo.("in%.mov".format(index), "mosh%.mov".format(index),{ cond.signalOne; "moshed a movie".postln; }); //  inconsistent with where I prepend addresses with vidsPath, etc.

		cond.wait { File.exists(vidsPath ++ "mosh%.mov".format(index)) };

		// make movie into photos

		video2Frames.("mosh%.mov".format(index),index);

		45.wait;

		"made some frames".postln;

		// lightly corrupt each frame
		moshFrames.(pixPath,index,{ cond.signalOne; "moshed some frames".postln; });

		cond.wait { File.exists(pixPath ++ "img%-%.jpg".format(index + 1, frames)) };
		cond.signalOne;

	});

	cond.wait { File.exists(pixPath ++ "img%-%.jpg".format(iterations, frames)) };

	// use jpgs to create the music - one jpeg == one second?


	render.(renderName,iterations);

}).play;
)
19:52

