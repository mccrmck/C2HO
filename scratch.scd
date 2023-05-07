


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


fork{
	(900..999).do({ |i|
		var num = "000%".format(i + 1).keep(-4);
		var path = "/Users/mikemccormick/Library/Application Support/SuperCollider/Extensions/CH2O/pix/img2-%.jpg".format(num);
		~file2Audio.(path,i,20000);
		0.01.wait;
	})
}
