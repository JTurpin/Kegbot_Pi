<?php
/**
 * A bridge to cross the processing of serialport with websocket in php. This 
 * is used for the kegbot.
 */
require "class.PHPWebSocket.php";
require "php_serial.class.php";

class ATSerialWebSocket extends PHPWebSocket {

  const STATSFILE = 'kegstats.txt';
  const SERIAL_DEVICE = '/dev/ttyACM0';
  const SERIAL_BAUD_RATE = 115200;
  const SERIAL_PARITY = 'none';

  private $sh = null;   // Serial connection handle

  public function __construct() {
    // start up the serial port
    $this->sh = new phpSerial();

    try {
      $this->sh->deviceSet(self::SERIAL_DEVICE);

      // conf
      $this->sh->confBaudRate(self::SERIAL_BAUD_RATE);
      $this->sh->confParity(self::SERIAL_PARITY);

      if (! $this->sh->deviceOpen("r")) {
        throw new Exception("Could not open device.");
      }


    }
    catch (Exception $e) {
      die($e);
    }
  }

  // overwrite the wsStartServer function to add the reading of the serialport 
  // in the loop.
  public function wsStartServer($host, $port) {
    if (isset($this->wsRead[0])) return false;

    if (!$this->wsRead[0] = socket_create(AF_INET, SOCK_STREAM, SOL_TCP)) {
      return false;
    }
    if (!socket_set_option($this->wsRead[0], SOL_SOCKET, SO_REUSEADDR, 1)) {
      socket_close($this->wsRead[0]);
      return false;
    }
    if (!socket_bind($this->wsRead[0], $host, $port)) {
      socket_close($this->wsRead[0]);
      return false;
    }
    if (!socket_listen($this->wsRead[0], 10)) {
      socket_close($this->wsRead[0]);
      return false;
    }

    $write = array();
    $except = array();

    $nextPingCheck = time() + 1;
    while (isset($this->wsRead[0])) {
      $changed = $this->wsRead;
      $result = socket_select($changed, $write, $except, 1);

      if ($result === false) {
        socket_close($this->wsRead[0]);
        return false;
      }
      elseif ($result > 0) {
        foreach ($changed as $clientID => $socket) {
          if ($clientID != 0) {
            // client socket changed
            $buffer = '';
            $bytes = @socket_recv($socket, $buffer, 4096, 0);

            if ($bytes === false) {
              // error on recv, remove client socket (will check to send close frame)
              $this->wsSendClientClose($clientID, self::WS_STATUS_PROTOCOL_ERROR);
            }
            elseif ($bytes > 0) {
              // process handshake or frame(s)
              if (!$this->wsProcessClient($clientID, $buffer, $bytes)) {
                $this->wsSendClientClose($clientID, self::WS_STATUS_PROTOCOL_ERROR);
              }
            }
            else {
              // 0 bytes received from client, meaning the client closed the TCP connection
              $this->wsRemoveClient($clientID);
            }
          }
          else {
            // listen socket changed
            $client = socket_accept($this->wsRead[0]);
            if ($client !== false) {
              // fetch client IP as integer
              $clientIP = '';
              $result = socket_getpeername($client, $clientIP);
              $clientIP = ip2long($clientIP);

              if ($result !== false && $this->wsClientCount < self::WS_MAX_CLIENTS && (!isset($this->wsClientIPCount[$clientIP]) || $this->wsClientIPCount[$clientIP] < self::WS_MAX_CLIENTS_PER_IP)) {
                $this->wsAddClient($client, $clientIP);
              }
              else {
                socket_close($client);
              }
            }
          }
        }
      }

      // Read from the serial port
      $s = $this->sh->readPort();

      $str = '';
      if (strlen($s) > 0 ) {
        $str .= $s;
        if (!strpos($str, 'BB') && !strpos($str, 'DD')) {
          continue;
        }
        if (preg_match('/AA(.*)BB/', $str, $matches)) {
          $this->wsSendMessageToAll($matches[1]);
          echo $matches[1] . "\n";
          //write_stats($matches[1]);
        }
        if (preg_match('/CC(.*)DD/', $str, $matches)) {
          $this->wsSendMessageToAll($matches[1]);
          echo "--> " . $matches[1] . "\n";
        }

        echo '<<-' . $str . "";
        $str = '';
      }
      // end serialport stuff

      if (time() >= $nextPingCheck) {
        $this->wsCheckIdleClients();
        $nextPingCheck = time() + 1;
      }
    }

    return true; // returned when wsStopServer() is called
  }

  // send to All Clients
  function wsSendMessageToAll($message) {
    foreach ($this->wsClients as $clientID => $client) {
      $this->wsSend($clientID, $message);
    }
  }
}
