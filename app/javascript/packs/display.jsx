import React from 'react'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import axios from 'axios'

class Display extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      loaded: false,
      payload: {}
    };
  }

  componentDidMount() {
    this.startPolling();
  }

  startPolling() {
    var self = this;

    setTimeout(function() {
      self.fetch();
      self._timer = setInterval(self.fetch.bind(self), 300000);
    }, 1000);
  }

  fetch() {
    axios.get('/display.json').then(res => {
      if(this.state.payload.api_version && this.state.payload.api_version != res.data.api_version) {
        location.reload();
      }
      this.setState({ payload: res.data, loaded: true });
    });
  }

  launchIntoFullscreen() {
    if(document.requestFullscreen) {
      document.requestFullscreen();
    } else if(document.mozRequestFullScreen) {
      document.mozRequestFullScreen();
    } else if(document.webkitRequestFullscreen) {
      document.webkitRequestFullscreen();
    } else if(document.msRequestFullscreen) {
      document.msRequestFullscreen();
    }
  }

  render() {
    if(this.state.loaded == true) {
      return (
        <div className="display">
          <div className="header">
            <div className="header-left">
              <h1>{ this.state.payload.weather.current_temperature }</h1>
            </div>

            <div className="header-right">
              <h2>{ this.state.payload.weather.today_temperature_range }</h2>
            </div>

            <div className="weather-summary">{ this.state.payload.weather.summary }</div>
          </div>
          <ul className="calendar-events">
            {this.state.payload.day_groups[0].events.all_day.map(event =>
              <li className="event" key={ event.summary }>
                <i className={ "fa fa-fw fa-" + event.icon } />
                <span>{ event.summary }</span>
              </li>
            )}
            {this.state.payload.day_groups[0].events.periodic.map(event =>
              <li className="event" key={ event.summary }>
                <i className={ "fa fa-fw fa-" + event.icon } />
                <span>{ event.summary }</span>
                <span className="time">{ event.time }{ (event.location)  ? ", " + event.location.split(", ")[0] : "" }</span>
              </li>
            )}
          </ul>
          <hr />
          <ul className="calendar-events">
            <li className="event">
              <i className="fa fa-fw fa-thermometer-three-quarters" />
              <span>{this.state.payload.weather.tomorrow_temperature_range}</span>
            </li>

            {this.state.payload.day_groupsp[1].events.all_day.map(event =>
              <li className="event" key={ event.summary }>
                <i className={ "fa fa-fw fa-" + event.icon } />
                <span>{ event.summary }</span>
              </li>
            )}
            {this.state.payload.day_groupsp[1].events.periodic.map(event =>
              <li className="event" key={ event.summary }>
                <i className={ "fa fa-fw fa-" + event.icon } />
                <span>{ event.summary }</span>
                <span className="time">{ event.time }</span>
              </li>
            )}
          </ul>
          <div className="fullscreen"><a onClick={ this.launchIntoFullscreen }><i className="fa fa-fw fa-expand" /></a></div>
          <div className="timestamp">{ this.state.payload.timestamp }</div>
        </div>
      );
    } else {
      return (
        <div>
          <h1>Loading</h1>
        </div>
      );
    }
  }
}

document.addEventListener('DOMContentLoaded', () => {
  ReactDOM.render(
    <Display />,
    document.getElementById('root'),
  )
})
