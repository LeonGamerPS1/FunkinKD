package funkin.objects.gameplay;

class Rating {
	static private var scoreAddRatings:Map<String, Float> = ["sick" => 350, "good" => 200, "bad" => 100, "shit" => 50];

	static public inline function scoreAddfromRating(rating:String = "?"):Float {
		if (scoreAddRatings.exists(rating))
			return scoreAddRatings.get(rating);
		return 0;
	}
}
