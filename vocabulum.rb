#! /usr/bin/env ruby

class Verbum
  attr_reader :uebersetzungen, :treffsicherheit

  def initialize(id, uebersetzungen, treffsicherheit)
    @id = id
    @uebersetzungen = uebersetzungen
    @treffsicherheit = treffsicherheit
  end
end

class Corpus
  attr_reader :wortwolke, :sprachen

  def initialize(vondatei)
    @lima = Lima.new(vondatei)
    @wortwolke = {}
    @sprachen = @lima.sprachen

    # wortwolke_bilden
    @lima.dateiinhalt.each do |elementi|
      @wortwolke[elementi[0].to_i] = Verbum.new(elementi[0], elementi[1..-2], elementi[-1])
    end
  end

end

class Lima
  attr_reader :sprachen, :dateiinhalt

  def initialize(dateiname)
    @dateiname = dateiname
    @sprachen = []
    @dateiinhalt = []

    z = 0
    File.read(@dateiname).split("\n").each do |versus|
      versus.chomp! #Zeilenumbruch entfernen
      if z == 0
        @sprachen = versus.split(";")[1..-2]
      else
        @dateiinhalt << versus.split(";")
      end
      z += 1
    end
  end

  def get_languages
    sprachenzeile = File.open(self.dateiname, "r").split("\n").first
    return sprachenzeile.split(";")[1..-1] # lässt das erste, leere Element weg
  end

  def write_csv
    
  end
end

class Trainer

  def initialize(wortwolke,ausgangssprachennr,uebersetzungssprachennr,mixed=false)
    @wortwolke = wortwolke
    @ausgangssprachennr = ausgangssprachennr
    @uebersetzungssprachennr = uebersetzungssprachennr
    @mixed = mixed

  end

  def training()
    treffer = 0
    @wortwolke.size.times do
      id = rand(1..3)
      treffer += aenigma(id)
    end
    return treffer
  end

  def aenigma(id)
    verbum = @wortwolke[id]
    frage = verbum.uebersetzungen[@ausgangssprachennr]
    antwort = verbum.uebersetzungen[@uebersetzungssprachennr]
    print "Die Übersetzung für #{frage} lautet: "
    versuch = gets
    treffer = 0
    if versuch.chomp! == antwort
      puts "Jawoll"
      return 1
    else
      puts "Nope :-( :: #{antwort}"
      return 0
    end
  end

end

puts "Dann wollen wir mal..."
corpus = Corpus.new("verbi.csv")
ausgangssprache = corpus.sprachen.index("de")
uebersetzungssprache = corpus.sprachen.index("lat")
trainer = Trainer.new(corpus.wortwolke, ausgangssprache, uebersetzungssprache)
puts "Du hattest #{trainer.training} Treffer."