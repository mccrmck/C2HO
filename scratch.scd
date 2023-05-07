


(
var outPath = "/Users/mikemccormick/Library/Application Support/SuperCollider/Extensions/CH2O/audio/";
~file2Audio = { |inPath, outKey, sampleRate = 48000|
	var cond = CondVar();
	var file = File(inPath,"rb");
	var int8 = Int8Array.newClear( file.length );
	var factors = int8.size.factors;
	file.read( int8 );
	int8 = int8.resamp1(48000 * 120);// two minutes long
	int8 = int8.collectAs({ |i,j|  (i / 256).tanh },FloatArray);

	Routine{
		var audio = SoundFile.openWrite(
			outPath +/+ "%.wav".format(outKey).standardizePath,
			"wav",
			"float",
			2,
			sampleRate
		);
		audio.writeData( int8 );
		audio.close;
	}.play
}
)

~file2Audio.("/System/DriverKit/System/Library/dyld/dyld_shared_cache_arm64e","audio",48000)





