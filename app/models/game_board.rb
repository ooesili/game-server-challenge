class GameBoard

  def initialize(board = nil)
    @board = board
  end

  def fill_board(size, num_words)
    # create an empty game
    @board = empty_game(size)
    # keep going though random permutations of all of the words until a valid
    # game is created
    catch :done do
      # TODO: we might want to put a limit on retries to make sure that
      # infinite loops *never* happen, even though it seems extremely
      # unlikely with the default game size and word count
      loop do
        # count the number of insertions so that we know when we're done
        num_insertions = 0
        random_words(size).each do |word|
          # try to insert the word
          if insert_word(size, word)
            num_insertions += 1
            # stop if we've inserted all the words we needed to
            throw :done if num_insertions > num_words
          end
        end
        # create another empty game and start over if we didn't finish
        @board = empty_game(size)
      end
    end
    # replace nils with random characters
    @board.map! do |row|
      row.map! do |char|
        char or (65 + rand(26)).chr
      end
    end
  end

  # for serializetion
  def self.dump(game_board)
    game_board.instance_variable_get(:@board)
  end

  def self.load(board)
    new(board)
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

  def insert_word(game_size, word)
    # get a random direction
    word = word.reverse if rand(2) == 1
    word_size = word.size
    # set up starting position and direction
    case rand(4)
    when 0
      starty = rand(0...game_size)
      startx = rand(0..game_size - word_size)
      accessor = :over_access
    when 1
      starty = rand(0..game_size - word_size)
      startx = rand(0...game_size)
      accessor = :down_access
    when 2
      starty = rand(word_size..game_size) - 1
      startx = rand(0..game_size - word_size)
      accessor = :up_over_access
    when 3
      starty = rand(0..game_size - word_size)
      startx = rand(0..game_size - word_size)
      accessor = :down_over_access
    end
    # see if we can insert the word without changing anything
    ok_to_insert = word.each_char.with_index.all? do |char, i|
      y, x = self.send(accessor, starty, startx, i)
      [char,nil].include? @board[y][x]
    end
    # add the word if it's ok
    if ok_to_insert
      word.each_char.with_index.each do |char, i|
        y, x = self.send(accessor, starty, startx, i)
        @board[y][x] = char
      end
    end
    # let caller know whether or not the insertion worked
    ok_to_insert
  end

  def random_words(max_size)
    # only include normal words that are short enough
    words = all_words.select do |line|
      /^[a-zA-Z]+$/ =~ line and line.length <= max_size
    end
    words.shuffle!
  end

  # create a new empty game board
  def empty_game(size)
    Array.new(size) {Array.new(size, nil)}
  end

  # other methods shouldn't care where the words came from
  def all_words
    File.open '/usr/share/dict/words' do |f|
      f.each_line.map {|word| word.chomp.upcase}
    end
  end

end
