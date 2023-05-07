


(
var outPath = "/Users/mikemccormick/Library/Application Support/SuperCollider/Extensions/CH2O/audio/";
~file2Audio = { |inPath, outKey, sampleRate = 48000|
	var cond = CondVar();
	var file = File(inPath,"rb");
	var int8 = Int8Array.newClear( file.length );
	var factors = int8.size.factors;
	file.read( int8 );

	factors = factors.reject({ |i| i > 2 });
	factors = factors.add(1);

	factors.postln;

	Routine{
		int8 = int8.collectAs({ |i,j|  i / 256 },FloatArray);

		factors.asSet.do({ |numChans|
			var audio = SoundFile.openWrite(
				outPath +/+ "%%ch.wav".format(outKey,numChans).standardizePath,
				"wav",
				"float",
				numChans,
				sampleRate
			);
			audio.writeData( int8 );
			audio.close;
		})

	}.play
}
)