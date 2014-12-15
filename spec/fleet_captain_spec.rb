require 'spec_helper'

describe FleetCaptain do
  describe '.docker_repo_url' do
    it 'builds a docker compatible repo name without a registry' do
      expect( FleetCaptain.docker_repo_url(
        user: 'hackuman',
        name: 'app',
        tag:  'production'
      )).to eq 'hackuman/app:production'
    end

    it 'builds a docker compataible repo name with a registery' do
      expect( FleetCaptain.docker_repo_url(
        repo: 'http://quay.io',
        user: 'hackuman',
        name: 'app',
        tag:  'rollback'
      )).to eq 'http://quay.io/hackuman/app:rollback'
    end
  end
end
