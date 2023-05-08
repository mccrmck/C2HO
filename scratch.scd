


(
var outPath = "/Users/mikemccormick/Library/Application Support/SuperCollider/Extensions/CH2O/audio/";
~file2Audio = { |inPath, outKey, sampleRate = 48000|
	var cond = CondVar();
	var file = File(inPath,"rb");
	var int8 = Int8Array.newClear( file.length );
	var factors = int8.size.factors;
	file.read( int8 );
	int8 = int8.resamp1(sampleRate * 120 * 2);// two minutes long, two channels
	// int8 = int8.resamp1(sampleRate * (frames / frameRate) * 2).round(2).asInteger;
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
}
)

~file2Audio.("dyld_shared_cache_arm64e".resolveRelative,"test",24000)





