class GameBoard
  attr_accessor :board, :inserted_words

  def initialize(data = {})
    @board = data[:board]
    @inserted_words = data[:inserted_words]
    # set game_size if we were given a board
    @game_size = board.size if @board
  end

  def fill_board(game_size, num_words)
    # overwrite game size
    @game_size = game_size
    # create an empty game
    @board = empty_game
    # keep going though random permutations of all of the words until a valid
    # game is created
    catch :done do
      # TODO: we might want to put a limit on retries to make sure that
      # infinite loops *never* happen, even though it seems extremely
      # unlikely with the default game size and word count
      loop do
        # count the number of insertions so that we know when we're done
        @inserted_words = []
        random_words(@game_size).each do |word|
          # try to insert the word
          if insert_word(word)
            @inserted_words << word
            # stop if we've inserted all the words we needed to
            throw :done if @inserted_words.size == num_words
          end
        end
        # create another empty game and start over if we didn't finish
        @board = empty_game
      end
    end
    # replace nils with random characters
    @board.map! do |row|
      row.map! do |char|
        char or (65 + rand(26)).chr
      end
    end
  end

  def find_word(word)
    # calculate the word size once
    word_size = word.size
    # try the word in reverse too
    [word, word.reverse].any? do |this_word|
      # the game board is all uppercase
      this_word.upcase!
      # try every direction
      4.times.any? do |direction|
        # get coordinate ranges to iterate over
        yrange, xrange, accessor = get_coords_range(word_size, direction)
        # iterate over each starting point
        yrange.any? do |ystart|
          xrange.any? do |xstart|
            # try to find the word
            this_word.each_char.with_index.all? do |char, i|
              y, x = self.send(accessor, ystart, xstart, i)
              @board[y][x] == char
            end
          end
        end
      end
    end
  end

  # for serializetion
  def self.dump(game_board)
    {
      board: game_board.board,
      inserted_words: game_board.inserted_words,
    }
  end

  def self.load(data)
    if data
      new(data)
    else
      new
    end
  end

  # other methods shouldn't care where the words came from
  ALL_WORDS = File.open '/usr/share/dict/words' do |f|
    words = []
    f.each_line do |word|
      if /^[A-Za-z]+$/ =~ word
        words.push word.chomp.upcase
      end
    end
    words
  end

  private

  # coordinate translators
  def over_access(y, x, delta)
    [y, x+delta]
  end
  def down_access(y, x, delta)
    [y+delta, x]
  end
  def up_over_access(y, x, delta)
    [y-delta, x+delta]
  end
  def down_over_access(y, x, delta)
    [y+delta, x+delta]
  end

  def get_coords_range(word_size, direction)
    case direction
    when 0
      yrange = 0...@game_size
      xrange = 0..@game_size - word_size
      accessor = :over_access
    when 1
      yrange = 0..@game_size - word_size
      xrange = 0...@game_size
      accessor = :down_access
    when 2
      yrange = (word_size - 1)..(@game_size - 1)
      xrange = 0..@game_size - word_size
      accessor = :up_over_access
    when 3
      yrange = 0..@game_size - word_size
      xrange = 0..@game_size - word_size
      accessor = :down_over_access
    end
    [yrange, xrange, accessor]
  end

  def insert_word(word)
    # get a random direction
    word = word.reverse if rand(2) == 1
    # set up starting position and direction
    yrange, xrange, accessor = get_coords_range(word.size, rand(4))
    ystart = rand(yrange)
    xstart = rand(xrange)
    # see if we can insert the word without changing anything
    ok_to_insert = word.each_char.with_index.all? do |char, i|
      y, x = self.send(accessor, ystart, xstart, i)
      [char,nil].include? @board[y][x]
    end
    # add the word if it's ok
    if ok_to_insert
      word.each_char.with_index.each do |char, i|
        y, x = self.send(accessor, ystart, xstart, i)
        @board[y][x] = char
      end
    end
    # let caller know whether or not the insertion worked
    ok_to_insert
  end

  def random_words(max_size)
    # only include normal words that are short enough
    words = ALL_WORDS.select{|line| line.length <= max_size}
    words.shuffle!
  end

  # create a new empty game board
  def empty_game
    Array.new(@game_size) {Array.new(@game_size, nil)}
  end

end
