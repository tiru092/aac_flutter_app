-- Migration: Add comprehensive default icons and categories
-- Created: 2025-10-07
-- Description: Adds all emoji-based symbols and category icons to global defaults

-- Clear existing data and reset sequences
DELETE FROM global_default_symbols;
DELETE FROM global_default_categories;

-- Insert comprehensive category data with proper icon paths
INSERT INTO global_default_categories (name, icon_path, color_code, sort_order) VALUES
('Food & Drinks', 'assets/icons/food.png', 16740459, 1),
('Vehicles', 'assets/icons/vehicles.png', 5099972, 2),
('Emotions', 'assets/icons/emotions.png', 16770669, 3),
('Actions', 'assets/icons/actions.png', 7103487, 4),
('Family', 'assets/icons/family.png', 16744259, 5),
('Basic Needs', 'assets/icons/needs.png', 5357670, 6)
ON CONFLICT (name) DO UPDATE SET
  icon_path = EXCLUDED.icon_path,
  color_code = EXCLUDED.color_code,
  sort_order = EXCLUDED.sort_order,
  updated_at = NOW();

-- Insert comprehensive symbol data with PNG asset paths
INSERT INTO global_default_symbols (label, image_path, category_name, description, speech_text) VALUES
-- Food & Drinks (Essential nutrition symbols)
('Apple', 'assets/symbols/Apple.png', 'Food & Drinks', 'Red apple fruit for eating', 'apple'),
('Water', 'assets/symbols/Water.png', 'Food & Drinks', 'Glass of water to drink', 'water'),
('Milk', 'assets/symbols/milk.png', 'Food & Drinks', 'Glass of milk to drink', 'milk'),
('Bread', 'assets/symbols/bread.png', 'Food & Drinks', 'Slice of bread to eat', 'bread'),
('Banana', 'assets/symbols/banana.png', 'Food & Drinks', 'Yellow banana fruit', 'banana'),
('Orange', 'assets/symbols/orange.png', 'Food & Drinks', 'Orange citrus fruit', 'orange'),
('Grape', 'assets/symbols/grape.png', 'Food & Drinks', 'Purple grapes', 'grapes'),
('Strawberry', 'assets/symbols/strawberry.png', 'Food & Drinks', 'Red strawberry fruit', 'strawberry'),
('Pizza', 'assets/symbols/pizza.png', 'Food & Drinks', 'Slice of pizza', 'pizza'),
('Burger', 'assets/symbols/burger.png', 'Food & Drinks', 'Hamburger sandwich', 'burger'),
('Sandwich', 'assets/symbols/sandwich.png', 'Food & Drinks', 'Sandwich with filling', 'sandwich'),
('Juice', 'assets/symbols/juice.png', 'Food & Drinks', 'Fresh fruit juice', 'juice'),
('Coffee', 'assets/symbols/coffee.png', 'Food & Drinks', 'Cup of coffee', 'coffee'),
('Tea', 'assets/symbols/tea.png', 'Food & Drinks', 'Cup of tea', 'tea'),
('Cookie', 'assets/symbols/cookie.png', 'Food & Drinks', 'Sweet cookie', 'cookie'),
('Cake', 'assets/symbols/cake.png', 'Food & Drinks', 'Birthday cake', 'cake'),
('Ice Cream', 'assets/symbols/icecream.png', 'Food & Drinks', 'Cold ice cream', 'ice cream'),

-- Vehicles (Transportation symbols)
('Car', 'assets/symbols/Car.png', 'Vehicles', 'Family car for transportation', 'car'),
('Bus', 'assets/symbols/bus.png', 'Vehicles', 'Public bus transportation', 'bus'),
('Train', 'assets/symbols/train.png', 'Vehicles', 'Train for long distance', 'train'),
('Airplane', 'assets/symbols/airplane.png', 'Vehicles', 'Airplane for flying', 'airplane'),
('Bicycle', 'assets/symbols/bicycle.png', 'Vehicles', 'Two-wheel bicycle', 'bicycle'),
('Motorcycle', 'assets/symbols/motorcycle.png', 'Vehicles', 'Fast motorcycle', 'motorcycle'),
('Truck', 'assets/symbols/truck.png', 'Vehicles', 'Large delivery truck', 'truck'),
('Taxi', 'assets/symbols/taxi.png', 'Vehicles', 'Yellow taxi cab', 'taxi'),
('Boat', 'assets/symbols/boat.png', 'Vehicles', 'Sailing boat', 'boat'),
('Helicopter', 'assets/symbols/helicopter.png', 'Vehicles', 'Flying helicopter', 'helicopter'),

-- Emotions (Feeling symbols)
('Happy', 'assets/symbols/happy.png', 'Emotions', 'Feeling happy and joyful', 'happy'),
('Sad', 'assets/symbols/sad.png', 'Emotions', 'Feeling sad or upset', 'sad'),
('Angry', 'assets/symbols/angry.png', 'Emotions', 'Feeling angry or mad', 'angry'),
('Excited', 'assets/symbols/excited.png', 'Emotions', 'Feeling excited and energetic', 'excited'),
('Scared', 'assets/symbols/scared.png', 'Emotions', 'Feeling scared or afraid', 'scared'),
('Tired', 'assets/symbols/tired.png', 'Emotions', 'Feeling tired or sleepy', 'tired'),
('Love', 'assets/symbols/love.png', 'Emotions', 'Feeling love or affection', 'love'),
('Surprised', 'assets/symbols/surprised.png', 'Emotions', 'Feeling surprised or amazed', 'surprised'),

-- Actions (Activity symbols)
('Eat', 'assets/symbols/eat.png', 'Actions', 'Eating food', 'eat'),
('Drink', 'assets/symbols/drink.png', 'Actions', 'Drinking liquid', 'drink'),
('Sleep', 'assets/symbols/sleep.png', 'Actions', 'Going to sleep or rest', 'sleep'),
('Play', 'assets/symbols/play.png', 'Actions', 'Playing games or having fun', 'play'),
('Run', 'assets/symbols/run.png', 'Actions', 'Running fast', 'run'),
('Walk', 'assets/symbols/walk.png', 'Actions', 'Walking slowly', 'walk'),
('Jump', 'assets/symbols/jump.png', 'Actions', 'Jumping up and down', 'jump'),
('Sit', 'assets/symbols/sit.png', 'Actions', 'Sitting down', 'sit'),
('Read', 'assets/symbols/read.png', 'Actions', 'Reading a book', 'read'),
('Write', 'assets/symbols/write.png', 'Actions', 'Writing with pen', 'write'),
('Draw', 'assets/symbols/draw.png', 'Actions', 'Drawing pictures', 'draw'),
('Sing', 'assets/symbols/sing.png', 'Actions', 'Singing songs', 'sing'),
('Dance', 'assets/symbols/dance.png', 'Actions', 'Dancing to music', 'dance'),
('Hug', 'assets/symbols/hug.png', 'Actions', 'Giving a hug', 'hug'),
('Wave', 'assets/symbols/wave.png', 'Actions', 'Waving hello or goodbye', 'wave'),
('Clap', 'assets/symbols/clap.png', 'Actions', 'Clapping hands', 'clap'),
('Point', 'assets/symbols/point.png', 'Actions', 'Pointing at something', 'point'),

-- Family (People symbols)
('Mom', 'assets/symbols/mom.png', 'Family', 'Mother or mom', 'mom'),
('Dad', 'assets/symbols/dad.png', 'Family', 'Father or dad', 'dad'),
('Baby', 'assets/symbols/baby.png', 'Family', 'Baby or infant', 'baby'),
('Child', 'assets/symbols/child.png', 'Family', 'Young child', 'child'),
('Grandma', 'assets/symbols/grandma.png', 'Family', 'Grandmother', 'grandma'),
('Grandpa', 'assets/symbols/grandpa.png', 'Family', 'Grandfather', 'grandpa'),
('Family', 'assets/symbols/family.png', 'Family', 'Family members together', 'family'),
('Friend', 'assets/symbols/friend.png', 'Family', 'Close friend', 'friend'),
('Teacher', 'assets/symbols/teacher.png', 'Family', 'School teacher', 'teacher'),
('Doctor', 'assets/symbols/doctor.png', 'Family', 'Medical doctor', 'doctor'),
('Police', 'assets/symbols/police.png', 'Family', 'Police officer', 'police'),

-- Basic Needs (Essential items)
('Home', 'assets/symbols/home.png', 'Basic Needs', 'House or home', 'home'),
('Toilet', 'assets/symbols/toilet.png', 'Basic Needs', 'Bathroom or toilet', 'toilet'),
('Help', 'assets/symbols/help.png', 'Basic Needs', 'Need help or assistance', 'help'),
('Bed', 'assets/symbols/bed.png', 'Basic Needs', 'Bed for sleeping', 'bed'),
('Shower', 'assets/symbols/shower.png', 'Basic Needs', 'Taking a shower', 'shower'),
('Clothes', 'assets/symbols/clothes.png', 'Basic Needs', 'Clothing to wear', 'clothes'),
('Shoes', 'assets/symbols/shoes.png', 'Basic Needs', 'Shoes for feet', 'shoes'),
('Medicine', 'assets/symbols/medicine.png', 'Basic Needs', 'Medicine when sick', 'medicine'),
('Phone', 'assets/symbols/phone.png', 'Basic Needs', 'Mobile phone', 'phone'),
('Computer', 'assets/symbols/computer.png', 'Basic Needs', 'Computer or laptop', 'computer'),
('TV', 'assets/symbols/tv.png', 'Basic Needs', 'Television', 'TV'),
('Book', 'assets/symbols/book.png', 'Basic Needs', 'Book for reading', 'book'),
('Pen', 'assets/symbols/pen.png', 'Basic Needs', 'Pen for writing', 'pen'),
('Bag', 'assets/symbols/bag.png', 'Basic Needs', 'Bag for carrying', 'bag'),
('Watch', 'assets/symbols/watch.png', 'Basic Needs', 'Watch for time', 'watch'),
('Umbrella', 'assets/symbols/umbrella.png', 'Basic Needs', 'Umbrella for rain', 'umbrella'),
('Sunglasses', 'assets/symbols/sunglasses.png', 'Basic Needs', 'Sunglasses for sun', 'sunglasses')
ON CONFLICT (label, category_name) DO UPDATE SET
  image_path = EXCLUDED.image_path,
  description = EXCLUDED.description,
  speech_text = EXCLUDED.speech_text,
  updated_at = NOW();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_global_default_symbols_category ON global_default_symbols(category_name);
CREATE INDEX IF NOT EXISTS idx_global_default_symbols_label ON global_default_symbols(label);

-- Add comments
COMMENT ON TABLE global_default_symbols IS 'Default symbols available to all users with PNG asset paths';
COMMENT ON TABLE global_default_categories IS 'Default categories available to all users with PNG icon paths';
COMMENT ON COLUMN global_default_symbols.image_path IS 'Local PNG asset path (e.g., assets/symbols/apple.png)';
COMMENT ON COLUMN global_default_categories.icon_path IS 'Local PNG icon path (e.g., assets/icons/food.png)';