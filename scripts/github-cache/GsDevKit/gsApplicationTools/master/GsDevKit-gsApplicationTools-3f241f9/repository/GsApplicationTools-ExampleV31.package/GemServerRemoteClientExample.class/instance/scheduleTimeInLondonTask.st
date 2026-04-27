tasks
scheduleTimeInLondonTask
	"http://www.time.org no longer exists use https://time.is if you must ... for now not used"

	^ (self taskClass
		value: [ 
			| timeInLondon |
			"should extract the time from the html; not the most robust parsing algorithmn"
			timeInLondon := (HTTPSocket
				httpGet: 'http://www.time.org/zones/Europe/London.php')
				throughAll: 'Europe/London - ';
				upTo: Character space.
			'(from http://www.time.org), time in London is: ' , timeInLondon ])
		expectedDelay: 600;
		addToQueue: self