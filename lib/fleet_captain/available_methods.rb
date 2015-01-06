module FleetCaptain
  UNIT_DIRECTIVES = %w(
    Description
    Name
    After
    Requires
  )

  SERVICE_DIRECTIVES = %w(
    ExecStart
    ExecStartPre
    ExecStartPost
    ExecReload
    ExecStop
    ExecStopPost
    RestartSec
    Type
    RemainAfterExit
    BusName
    BusPolicy
    TimeoutStartSec
    TimeoutStopSec
    TimeoutSec
    WatchdogSec
    Restart
    SuccessExitStatus
    RestartPreventExitStatus
    RestartForceExitStatus
    PermissionsStartOnly
    RootDirectoryStartOnly
    NonBlocking
    NotifyAccess
    Sockets
    StartLimitInterval
    StartLimitBurst
    StartLimitAction
    FailureAction
    RebootArgument
    GuessMainPID
    PIDFile
  )

  XFLEET_DIRECTIVES = %w(
    MachineID
    MachineOf
    MachineMetadata
    Conflicts
    Global
  )

  MULTI_VALUE_DIRECTIVES = %w(
    ExecStart
    ExecStartPre
    ExecStartPost
    ExecReload
    ExecStop
    ExecStopPost
    After
    Requires
    Conflicts
  )

  def self.available_methods
    return @available_methods if @available_methods
    @available_methods = available_directives.map { |name| name.underscore }
  end

  def self.multi_value_directives
    @multi_value_directives ||= MULTI_VALUE_DIRECTIVES.map(&:underscore)
  end
  
  def self.available_directives
    @available_directives ||= (UNIT_DIRECTIVES + SERVICE_DIRECTIVES + XFLEET_DIRECTIVES)
  end
end
