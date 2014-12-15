require 'fleet_captain/commands/hash_options'

describe FleetCaptain::Commands::HashOptions do
  # A lot of unix CLI utilities take the form of
  #
  # command sub-command <a list of options> target
  #
  # this class provides a VERY basic way to convert hashes
  # into that kind of structure
  #
  # { run: 'thing' }
  #
  # 'run thing'
  #
  # { run: ['thing', p: 30] }
  #
  # 'run -p 30 thing'
  #
  # { run: { ports: 30, h: true } }
  #
  # 'run -p 30 -h'
  #

  it 'converts strings in a hash into trailing command targets' do
    expect(described_class.create( { run: 'thing' }).to_s).to eq 'run thing'
  end

  it 'converts strings in a hash into trailing command targets' do
    expect(described_class.create( { run: ['thing', p: 30] }).to_s).to eq 'run -p 30 thing'
  end

  it 'converts strings in a hash into trailing command targets' do
    expect(described_class.create( { run: { ports: 30, h: true } }).to_s).to eq 'run --ports 30 -h'
  end
end
