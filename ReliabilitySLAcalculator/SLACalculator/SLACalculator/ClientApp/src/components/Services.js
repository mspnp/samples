import React, { Component } from 'react';
import './Styles.css';

export class Services extends Component {

    static renderServicesTable(services, selectService) {
        return (
            <div className="servicesTable">
                {services.map(service =>
                    <div className="serviceLayout" onClick={() => selectService(service.name)}>{service.name}</div>
                )}
            </div>
        );
    }

    render() {
        let contents = Services.renderServicesTable(this.props.dataSource, this.props.onSelectService);

        return (
            <div>
                {contents}
            </div>
        );
    }
}
