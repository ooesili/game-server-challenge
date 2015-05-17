Game Server Challenge [![Build Status](https://travis-ci.org/ooesili/game-server-challenge.svg?branch=master)](https://travis-ci.org/ooesili/game-server-challenge)
======================

This application is up and running on
https://game-server-challenge.herouapp.com


Introduction
----------------------

This application is a solution to a challenge problem posed [here][1].  The
application can be setup by cloning it down and running `bin/setup`.  The
application is an API based competitive word-search like game whose details are
described in detail in [the aforementioned link][1].


Design Overview
----------------------

### Initial Board Algorithm

One of the more interesting algorithms inside of this application is for the
creation of the initial game board.  The constraints defined in the challenge
require that the initial game board be a randomly generated 15 by 15 grid of
alphabetic characters containing at least 10 English words.  This words may be
place vertically or horizontally, and optionally diagonally.  This application
allows words to be places in all three directions, forwards and backwards.

It would be fairly easy to randomly generate a 15 by 15 grid of alphabetic
characters, iterate through a list of English words and check that at least 10
words are contained.  If that grid did not contain at least 10 words, another
could be generated and checked again.  Ignoring the probability that any
randomly generated grid might not meet this 10 word requirement, this algorithm
is highly inefficient.

Had we placed even a single word on the grid before filling the rest with
random characters, we would have theoretically already cut down the run time by
10%.  This is exactly the kind of approach used for this application.

The code that generates the initial game board can be found in
`app/models/game_board.rb`, in the `.fill_board` method.  The general steps are
as follows:

* A 15 by 15 empty grid is created, where every character is a space.

* A large list of English words is shuffled into a random order.

* Each word in the randomized list is iterated over, and an attempt is made to
insert into the grid in a random position and direction.

* If the word can be inserted into the grid without changing any of the
  previously placed characters, the word will be inserted at that position and
will be recorded into the array.  To illustrate this, if the grid is as follows
(`.` will represent spaces for this example):

```
...............
...............
..S............
..A.F..........
..N..E.........
..G...R........
..U....R.......
..I.....E......
..N......T.....
..E............
...............
...............
...............
...............
...............
```

the word 'internet' could be inserted like this:

```
...............
...............
..S............
..A.F..........
..N..E.........
..G...R........
..U....R.......
..INTERNET.....
..N......T.....
..E............
...............
...............
...............
...............
...............
```

because the word is only placed over spaces and characters that already match
the corresponding characters in word.

* If the end of the list of words is reached and 10 words were not inserted,
the list of inserted words is cleared, the list of all words is shuffled
again, and the algorithm is restarted.

The danger here is that the there is no guarantee that this algorithm will ever
end.  However, an infinite loop _seems_ extremely unlikely with the given board
size and number of required words, and the test that runs this algorithm seems
to run at a very consistent speed.

### Word Finding Algorithm

The algorithm to see if a word is inside is as follows.

* Do the following for the word, its reverse:

* Do the following for each direction (up, down, up and over, down and over):

* Find the range of starting points.  That is restrict the X and Y values to
  those for which the word will actually fit into.

* See if every character in the word matches every corresponding character in
  the grid for the given starting position and direction.

### API overview

All of the code for API interactions is contained within `GameController`,
which can be found in `app/controllers/game_controller.rb`.  The logic here is
quite straight-forward, delegating most business logic to the `Game` model,
handling error cases, and responding with the appropriate data.  The API
conforms very closely with what the challenge specifies.

### Notable Design Choices

As per Ruby on Rails convention, the controllers and ActiveRecord models were
attempted to be kept pretty slim.  Controllers should mainly only be
responsible for wiring data from models into responses and shielding models
from the nuances of formatting data taken from request parameters.
ActiveRecord models should mainly only handle data persistence.  Most of the
game logic lives in a separate GameBoard class whose main concern is such.

### Scalability

Since games are stored in the database and are accessed by a unique ID, games
can be multiple games can already be play simultaneously.  Since only one
player can play at a time, and postgreSQL guarantees atomicity during update
operations, there is no risk of two players being able to get points for the
same word when their requests hit `/play` at the same time.

However, since the web server that is being used (`puma`) is multi-threaded, a
player could theoretically hit the `/play` endpoint with two requests in a
quick enough succession that he/she may be able to get points for two words on
a single turn.  This risk could be eliminated by creating an in-memory or
in-database locking mechanism created on a per-game-ID basis that would be hit
as soon as the `play endpoint` is.  This would mean that everything from
loading the game from the database and performing the turn-playing logic, to
saving the game back into the database would be locked into a single thread.
Since the locks would be on per-game-ID basis, there would be no performance
hit delivered to other concurrent games, other than the tiny overhead of the
computing power required to actually lock and unlock the mutex.

The lock could also be restricted to endpoints that mutate the database, so
that `/info` would not need to hit the lock, meaning it wouldn't not have to
wait until other threads have released it in order to respond with information.

### API Usage Examples

The following are `curl` calls that demonstrate the various API endpoints.  The
output of the commands were ran through `json_pp` for legibility.

#### /create
```bash
$ curl -s 'http://localhost:3000/create' | json_pp
{
   "nick" : "romagueradicki",
   "player_id" : "a0b4beff-ab65-4630-8493-e2c5dce67d77",
   "game_id" : "5dd33b11-f4bb-4ccd-9f32-b5b91c53dd7c"
}
```

#### /join
```bash
$ curl -s 'http://localhost:3000/join?game_id=5dd33b11-f4bb-4ccd-9f32-b5b91c53dd7c' | json_pp
{
   "nick" : "kleingleichner",
   "player_id" : "3cae31dd-0bc8-446f-a2a5-c9c5b8dd26e9",
   "registered" : true
}
```

#### /start
```bash
$ curl -s 'http://localhost:3000/start?game_id=5dd33b11-f4bb-4ccd-9f32-b5b91c53dd7c&player_id=a0b4beff-ab65-4630-8493-e2c5dce67d77' | json_pp
{
   "grid" : [
      "YYTOPTATIVESZVI",
      "WSSENSSELKCEPSG",
      "HJVKOFOKSKIVAYG",
      "UCLATNEMITSEVEV",
      "VCTOQVGXFJYBLPZ",
      "VBKJXQAEDYYWITZ",
      "DSEHEXUCILHNHQV",
      "DTTAILXDANXEHUU",
      "IEUUWZDSGTCKWZM",
      "AZBMIRACHOKDAPC",
      "SEADPUTAPLEYISM",
      "PCLLAAYHACPFVQI",
      "ISBIAEOTPLTVYUG",
      "NANNDRHTESKCIHT",
      "ESGWANNASCMEJLQ"
   ],
   "success" : true,
   "message" : "all good"
}
```

#### /play
```bash
$ curl -s 'http://localhost:3000/play?game_id=5dd33b11-f4bb-4ccd-9f32-b5b91c53dd7c&player_id=a0b4beff-ab65-4630-8493-e2c5dce67d77&word=specklessness' | json_pp
{
   "success" : true,
   "score" : 13
}
```

#### /info
```bash
$ curl -s 'http://localhost:3000/info?game_id=5dd33b11-f4bb-4ccd-9f32-b5b91c53dd7c&player_id=3cae31dd-0bc8-446f-a2a5-c9c5b8dd26e9' | json_pp
{
   "scores" : {
      "kleingleichner" : 0,
      "romagueradicki" : 13,
      "zboncakspinka" : 0
   },
   "current_player" : "zboncakspinka",
   "words_done" : [
      "specklessness"
   ],
   "game_status" : "In Play",
   "turn_seq" : [
      "zboncakspinka",
      "kleingleichner",
      "romagueradicki"
   ],
   "grid" : [
      "YYTOPTATIVESZVI",
      "WSSENSSELKCEPSG",
      "HJVKOFOKSKIVAYG",
      "UCLATNEMITSEVEV",
      "VCTOQVGXFJYBLPZ",
      "VBKJXQAEDYYWITZ",
      "DSEHEXUCILHNHQV",
      "DTTAILXDANXEHUU",
      "IEUUWZDSGTCKWZM",
      "AZBMIRACHOKDAPC",
      "SEADPUTAPLEYISM",
      "PCLLAAYHACPFVQI",
      "ISBIAEOTPLTVYUG",
      "NANNDRHTESKCIHT",
      "ESGWANNASCMEJLQ"
   ]
}
```

### Test Coverage

Along with the `curl` calls displayed above, API behaviour can be seen and
verified through the comprehensive RSpec testing suite provided for the
`GameController`.  The tests cover successful interactions as well as a
multitude of failure cases.

A single test is also written for the `GameBoard` model which verifies that
randomly generated boards do in fact contain the 10 inserted words that the
`fill_board` method records.


[1]: https://sites.google.com/a/tworoads.co.in/index/home/competitions-and-open-questions/game-server-challenge
