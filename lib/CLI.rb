class CLI
  def title_screen
    loop do
      puts "Welcome to Super Heroes Arena"
      puts "1.Start a new game \n2.Continue game \n3.Exit"
      input = gets.chomp.to_i

      case input
      when 1
        start; break
      when 2
        puts "Please enter your name:"
        name = gets.chomp
        user = User.find_by(name: name)
        start_stage(user)
        #todo: show user hero and stats again before starting stage.
        #maybe? persist the original enemy from stage before quitting.
        break
      when 3
        puts "Good bye."; exit
      else
        puts "Enter a valid number."
      end
    end
  end

  def start
    puts "You entered a dark room..."
    puts "A bearded wizard appears"
    puts "Bearded Wizard: What the heck? Who are you? Why are you in my special place?"
    puts "Enter your name:"

    name = gets.chomp
    #first check if user already exists to kick them back to title screen
    user = User.find_by(name: name)
    if user == nil
      user = User.create(name: name)
    else
      puts "\nBearded Wizard: HEY! You already been here before. Continue your old game.\n\n"
      return title_screen
    end

    choose_a_hero(user)
  end

  def choose_a_hero(user)
    puts "\nBearded Wizard: So... for some reason you have entered the Superhero Fighting Arena"
    puts "Bearded Wizard: CHOOSE YOUR SUPERHERO AND FIGHT TO THE DEATH or to the end of the stages."
    puts "Bearded Wizard: You'll be given a choice between 5 random superheroes."

    sample_heroes = get_data.sample(5)

    loop do
      puts "Please pick one of the following:"
      puts "1.#{sample_heroes[0]["name"]} \n2.#{sample_heroes[1]["name"]} \n3.#{sample_heroes[2]["name"]} \n4.#{sample_heroes[3]["name"]} \n5.#{sample_heroes[4]["name"]}"
      input = gets.chomp.to_i
      if input < 1 || input > 5
        puts "Enter a valid number."
      else
        confirm(sample_heroes[input - 1], user)
        break
      end
    end
  end

  def confirm(hero_hash, user)
    # hero_url = hero_hash['images']['lg']
    # download_image(hero_url)
    # print_picture(hero_url.split('/').last)

    puts "#{hero_hash['name']} stats:"
    puts "HP: #{hero_hash['powerstats']['durability']}"
    puts "ATK: #{hero_hash['powerstats']['strength'] + hero_hash['powerstats']['combat']}"
    puts "DEF: #{hero_hash['powerstats']['durability'] + hero_hash['powerstats']['intelligence']}"
    puts "SPEED: #{hero_hash['powerstats']['speed']}"
    puts "\nBearded Wizard: Oh interesting... are you sure you want to pick this superhero?"
    puts "Type (Y) to confirm or (N) to go back and choose another superhero."

    loop do
      input = gets.chomp.downcase
      case input
      when 'y'
        puts "Bearded Wizard: I guess that's a good choice..."
        #save user's superhero choice and stats
        user.save_stats(hero_hash)
        #call stage
        start_stage(user)
        break
      when 'n'
        #go back to choose_a_hero
        choose_a_hero(user)
        break
      else
        puts "Beard Wizard: QUIT MESSING AROUND! TYPE IN Y OR N!"
      end
    end
  end

  def start_stage(user)
    puts "Bearded Wizard: Well then, it's time to FIGHT TO THE DEATH!"

    stage = Stage.find_by(user_id: user.id)

    if stage == nil
      stage = Stage.create(user_id: user.id, level: 1)
      enemy = Enemy.new()
      enemy_hash = get_data.sample(1).first
      enemy.save_stats(enemy_hash)
      stage.update(enemy_id: enemy.id)
    else
      #continue part
      #put out our hero name and stats
      puts "Continuing with #{user.superhero_name}."
      # download_image(user.picture_url)
      # print_picture(user.picture_url.split('/').last)
      sleep(2)

      #grab enemy data to set up continuing stage
      enemy_id = Stage.find_by(user_id: user.id).enemy_id
      enemy = Enemy.find(enemy_id)
    end

    count = stage.level
    until count == 5
      puts "\nSTAGE #{count} BEGIN!"
      puts "A challenger appears..."

      #print that you're fighting this enemy name
      # download_image(enemy.picture_url)
      # print_picture(enemy.picture_url.split('/').last)

      #start battle
      result = start_battle(stage)

      if result
        #loop for new stage but wait 2 seconds before starting
        #need to create new enemy
        enemy = Enemy.new()
        enemy_hash = get_data.sample(1).first
        enemy.save_stats(enemy_hash)
        stage.update(enemy_id: enemy.id)

        sleep(2)
        count += 1
        stage.update(level: count)
        #if we're on stage 5 you won!
        if count == 5
          victory(user)
          break
        end
      else
        game_over(user)
        break
      end
    end

    #win or lose delete stage data
    stage.delete_by_user_id(user.id)
  end

  def start_battle(stage)
    #find user and enemy
    user = User.find(stage.user_id)
    enemy = Enemy.find(stage.enemy_id)

    puts "\n#{enemy.name} entered the room looking to fight you."
    #start battle
    until user.hp <= 0 || enemy.hp <= 0
      #initialize temp def for defend action
      user.temp_def = 0
      enemy.temp_def = 0

      #grab enemy input
      enemy_input = stage.enemy_move

      puts "\nPick an action:"
      puts "1.Attack \n2.Defend \n3.Run away\n4.Quit"
      user_input = gets.chomp.to_i

      until user_input > 0 && user_input < 5
        puts "Please enter a valid # for action."
        user_input = gets.chomp.to_i
      end

      exit if user_input == 4

      stage.who_goes_first(user, enemy, user_input, enemy_input)
      sleep(1)
    end

    if user.hp <= 0
      return false
    else
      #we need to move stages
      puts "\nBearded Wizard: Wow! You beat #{enemy.name}!"
      return true
    end
  end

  def victory(user)
    puts "\nBearded Wizard: Woah! You actually won! That's incredible... congrats"
    print_picture("winner.jpg")

    play_again?(user)
  end

  def game_over(user)
    puts "\nBearded Wizard: Haha, I knew you'd lose."

    play_again?(user)
  end

  def play_again?(user)
    puts "Want to play again?"
    puts "Type (Y) to start over and try again or (N) to stop playing"

    loop do
      input = gets.chomp.downcase
      if input == 'y'
        choose_a_hero(user)
        break
      elsif input == 'n'
        break
      else
        puts "Type (Y) to start over and try again or (N) to stop playing"
      end
    end
  end

  def print_picture(url)
    Catpix::print_image url, center_x: true, limit_y: 1
  end

  def download_image(url)
    open(url) do |u|
      File.open(url.split('/').last, 'wb') {|f| f.write(u.read)}
    end
  end

  def get_data
    stats_string = RestClient.get('https://akabab.github.io/superhero-api/api/all.json')
    stats_array = JSON.parse(stats_string)
    #todo: reject heroes who have no-profile picture link
    stats_array
  end
end
