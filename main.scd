// CH2O AV

(
var pixPath    = "pix/".resolveRelative;
var vidsPath   = "vids/".resolveRelative;
var sourceImg  = "cabin.jpg".resolveRelative;
// var sourceImg  = "mntn.jpg".resolveRelative;
var renderName = "Sunday4.mov";
var frames     = 1200;
var frameRate  = 12;
var iterations = 3;
var dataFile   = "dyld_shared_cache_arm64e".resolveRelative;

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
				var offset = size * [0.2,0.4,0.7].choose;

				var index = ((offset + step)  % size).asInteger;
				// array[index] = array[index] >> 1 | array[index] << 1;                               //try some different moshing ideas
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
				0.01.wait;
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
				array[index] = -128.rrand(127);
				// array[index] = array[index] >> 1;
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
					var offset = size * [0.1,0.2,0.3].choose;

					var index = ((offset + step)  % size).asInteger;
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

	"ffmpeg -framerate % -i %img%-%04d.jpg % ".format(frameRate, pPath, iter, "%", vPath ++ movName).runInTerminal

};

var video2Frames = { |movName, iter|
	var pPath = pixPath.replace(" ","\\ ");
	var vPath = vidsPath.replace(" ","\\ ");

	"ffmpeg -r % -i % %img%-%04d.jpg".format(frameRate, vPath ++ movName, pPath, iter, "%").runInTerminal
};

var renderMov = { |movName,iter|
	var pPath = pixPath.replace(" ","\\ ");
	var vPath = "renders/".resolveRelative.replace(" ","\\ ");

	"ffmpeg -framerate % -i %img%-%04d.jpg % ".format(frameRate, pPath, iter, "%", vPath ++ movName).runInTerminal

};

var data2Audio = { |inPath, outKey, sampleRate = 48000|
	var cond = CondVar();
	var file = File(inPath,"rb");
	var int8 = Int8Array.newClear( file.length );
	var factors = int8.size.factors;
	file.read( int8 );
	int8 = int8.resamp1((sampleRate * (frames/frameRate) * 2).round(2).asInteger);
	int8 = int8.collectAs({ |i,j|  (i / 80).clip2().tanh * -6.dbamp },FloatArray);

	Routine{
		var audio = SoundFile.openWrite(
			"audio".resolveRelative +/+ "%.wav".format(outKey),
			"wav",
			"float",
			2,
			sampleRate
		);
		audio.writeData( int8 );
		audio.close;
	}.play
};

var renderTogether = {
	var inMov   = "renders/video.mov".resolveRelative.replace(" ","\\ ");
	var inAudio = "audio/audio.wav".resolveRelative.replace(" ","\\ ");
	var outPath = "renders/".resolveRelative.replace(" ","\\ ");

	"ffmpeg -i % -i % -c copy %".format(inMov,inAudio,outPath +/+ renderName ).runInTerminal
};

Routine({

	var cond = CondVar();

	// lightly corrupt a .jpg file several times
	moshPhoto.(sourceImg,{ cond.signalOne; "moshed a photo".postln });

	cond.wait { File.exists(pixPath ++ "img0-%.jpg".format(frames)) };

	iterations.do({ |index|

		// make frames into a movie

		frames2Video.("in%.mov".format(index),index);

		90.wait;

		cond.wait { File.exists(vidsPath ++ "in%.mov".format(index)) };

		"made a movie".postln;

		// corrupt the movie
		moshVideo.("in%.mov".format(index), "mosh%.mov".format(index),{ cond.signalOne; "moshed a movie".postln; }); //  inconsistent with where I prepend addresses with vidsPath, etc.

		cond.wait { File.exists(vidsPath ++ "mosh%.mov".format(index)) };

		// make movie into photos
		video2Frames.("mosh%.mov".format(index),index);

		32.wait;

		"made some frames".postln;

		// lightly corrupt each frame
		moshFrames.(pixPath,index,{ cond.signalOne; "moshed some frames".postln; });

		cond.wait { File.exists(pixPath ++ "img%-%.jpg".format(index + 1, frames)) };
		cond.signalOne;

	});

	cond.wait { File.exists(pixPath ++ "img%-%.jpg".format(iterations, frames)) };

	renderMov.("video.mov",iterations);

	data2Audio.(dataFile,"audio",24000);

	"here".postln;

	100.wait;

	renderTogether.()

}).play;
)

// must get callbacks from ffmpeg!

