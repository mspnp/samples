import React, { Component } from 'react';
import { DelayRender } from './DelayRender';
import './Styles.css';

export class Services extends Component {

    static renderServicesTable(services, selectService) {
        return (
            <div className="services-table">
                {services.map(service =>
                    <div className="service-layout" onClick={() => selectService(service.name)} title={"SLA: " + service.sla + " %"}>
                        <div className="service-content-left"><img src={"images/" + service.imageFile}></img></div>
                        <div className="service-content-right"><p>{service.name}</p></div>
                        <div className="service-notes">{service.notes}</div>
                    </div>
                )}
            </div>
        );
    }

    render() {
        if (this.props.dataSource.length > 0) {
            let contents = Services.renderServicesTable(this.props.dataSource, this.props.onSelectService);

            return (
                <DelayRender waitBeforeShow={1500}>
                    <div>
                        {contents}
                    </div>
                </DelayRender>
            );
        }
        else {
            return (<DelayRender waitBeforeShow={1500}><div><p className="no-results">Sorry, there are no products that match your search</p></div></DelayRender>);
        }
    }
}
