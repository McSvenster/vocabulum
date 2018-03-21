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

  def initialize(corpus,ausgangssprache,uebersetzungssprache,mixed=false)
    @corpus = corpus
    @ausgangssprache = ausgangssprache
    @uebersetzungsprache = uebersetzungssprache
    @mixed = mixed

  end

  def aenigma(id)
    verbum = @corpus.wortwolke[id]
    frage = verbum.uebersetzungen[@corpus.sprachen.index(@ausgangssprache)]
    antwort = verbum.uebersetzungen[@corpus.sprachen.index(@uebersetzungsprache)]
    return frage, antwort
  end

end

puts "Dann wollen wir mal..."
corpus = Corpus.new("verbi.csv")
trainer = Trainer.new(corpus, "de", "lat")
id = rand(1..3)
puts "#{trainer.aenigma(id).first} : #{trainer.aenigma(id).last}"